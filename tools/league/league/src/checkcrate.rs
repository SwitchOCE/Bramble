//! `league check-crate <path> --name <red|blue>`: the crate rules of brief section 5a.
//!
//! 1. The manifest: only `[package]`, `[lib]` and `[dependencies]`, and every dependency on
//!    the allowlist (`ALLOWED_DEPS`; to allow a vendored crate, add it there and to
//!    `vendor/`). No build script, links, proc-macro or workspace keys.
//! 2. The files: no `build.rs`, no `.cargo` folder, no symbolic links.
//! 3. `#![forbid(unsafe_code)]` at the crate root (`src/lib.rs`).
//! 4. A token scan of every `.rs` file (comments and strings stripped) for the banned items:
//!    `unsafe`, `static`, `thread_local!`, `OnceLock`, `LazyLock`, `lazy_static`, `once_cell`,
//!    atomics, `extern`, `#[no_mangle]`, `#[export_name]`, `#[link_section]`, `asm!`,
//!    `env!`/`option_env!`, time types, the harness module; any `std`/`core`/`alloc` path whose
//!    first segment is not on `STD_ALLOWED` (so `std::thread`, `std::fs`, `std::net`,
//!    `std::process`, `std::env`, `std::time`, `std::io`, `std::sync` and the rest are out),
//!    including inside `use std::{...}` groups, `std::*` globs and `use std as x`;
//!    `include!`/`include_str!`/`include_bytes!` and `#[path]` must name a literal path that
//!    stays inside the crate folder.
//! 5. A build in a fresh tree holding only the engine, the API, the harness, a registry with
//!    only this crate, and the vendored crates: `--offline --locked`, `CARGO_BUILD_JOBS=2`.
use std::path::{Component, Path, PathBuf};
use std::process::Command;

/// Crates a team crate may depend on.
pub const ALLOWED_DEPS: &[&str] = &["league-api"];

/// First path segments allowed after `std::`, `core::` or `alloc::`.
pub const STD_ALLOWED: &[&str] = &[
    "any",
    "array",
    "ascii",
    "borrow",
    "boxed",
    "char",
    "clone",
    "cmp",
    "collections",
    "convert",
    "default",
    "error",
    "f32",
    "f64",
    "fmt",
    "hash",
    "hint",
    "i8",
    "i16",
    "i32",
    "i64",
    "i128",
    "isize",
    "iter",
    "marker",
    "mem",
    "num",
    "ops",
    "option",
    "prelude",
    "primitive",
    "rc",
    "cell",
    "result",
    "slice",
    "str",
    "string",
    "u8",
    "u16",
    "u32",
    "u64",
    "u128",
    "usize",
    "vec",
];

const BANNED: &[(&str, &str)] = &[
    ("unsafe", "unsafe code"),
    ("static", "a static: seats must share nothing"),
    ("thread_local", "thread-local state"),
    ("OnceLock", "global state"),
    ("LazyLock", "global state"),
    ("lazy_static", "global state"),
    ("once_cell", "global state"),
    ("extern", "extern"),
    ("no_mangle", "#[no_mangle]"),
    ("export_name", "#[export_name]"),
    ("link_section", "#[link_section]"),
    ("asm", "asm!"),
    ("global_asm", "global_asm!"),
    ("naked_asm", "naked_asm!"),
    ("env", "reading the environment"),
    ("option_env", "reading the environment"),
    ("Instant", "reading the time"),
    ("SystemTime", "reading the time"),
    ("UNIX_EPOCH", "reading the time"),
    ("harness", "the harness's own module"),
    // Memory addresses could carry a message from one seat to another.
    ("as_ptr", "memory addresses"),
    ("as_mut_ptr", "memory addresses"),
    ("into_raw", "memory addresses"),
    ("from_raw", "memory addresses"),
    ("addr_of", "memory addresses"),
    ("addr_of_mut", "memory addresses"),
    ("Pointer", "memory addresses"),
    ("leak", "memory addresses"),
];

#[derive(Debug, Clone, PartialEq)]
enum Tok {
    Ident(String),
    Str(String),
    Punct(String),
    Other,
}

struct Token {
    tok: Tok,
    line: usize,
}

fn tokenize(src: &str) -> Result<Vec<Token>, String> {
    let c: Vec<char> = src.chars().collect();
    let mut out = Vec::new();
    let mut i = 0;
    let mut line = 1;
    let at = |i: usize| c.get(i).copied().unwrap_or('\0');
    while i < c.len() {
        let ch = c[i];
        if ch == '\n' {
            line += 1;
            i += 1;
            continue;
        }
        if ch.is_whitespace() {
            i += 1;
            continue;
        }
        if ch == '/' && at(i + 1) == '/' {
            while i < c.len() && c[i] != '\n' {
                i += 1;
            }
            continue;
        }
        if ch == '/' && at(i + 1) == '*' {
            let mut depth = 0;
            loop {
                if i >= c.len() {
                    return Err(format!("line {line}: unterminated comment"));
                }
                if c[i] == '/' && at(i + 1) == '*' {
                    depth += 1;
                    i += 2;
                } else if c[i] == '*' && at(i + 1) == '/' {
                    depth -= 1;
                    i += 2;
                    if depth == 0 {
                        break;
                    }
                } else {
                    if c[i] == '\n' {
                        line += 1;
                    }
                    i += 1;
                }
            }
            continue;
        }
        // Raw strings: r"..", r#".."#, br"..", cr"..".
        let raw_start = match (ch, at(i + 1), at(i + 2)) {
            ('r', '"', _) | ('r', '#', _) => Some(i + 1),
            ('b', 'r', '"') | ('b', 'r', '#') | ('c', 'r', '"') | ('c', 'r', '#') => Some(i + 2),
            _ => None,
        };
        if let Some(mut j) = raw_start {
            let mut hashes = 0;
            while at(j) == '#' {
                hashes += 1;
                j += 1;
            }
            if at(j) == '"'
                && !(hashes > 0 && ch == 'r' && at(i + 1) == '#' && is_ident_start(at(i + 2)))
            {
                j += 1;
                let begin = j;
                loop {
                    if j >= c.len() {
                        return Err(format!("line {line}: unterminated raw string"));
                    }
                    if c[j] == '"' && (0..hashes).all(|k| at(j + 1 + k) == '#') {
                        break;
                    }
                    if c[j] == '\n' {
                        line += 1;
                    }
                    j += 1;
                }
                out.push(Token {
                    tok: Tok::Str(c[begin..j].iter().collect()),
                    line,
                });
                i = j + 1 + hashes;
                continue;
            }
        }
        // Ordinary and byte/C strings.
        if ch == '"' || ((ch == 'b' || ch == 'c') && at(i + 1) == '"') {
            let mut j = if ch == '"' { i + 1 } else { i + 2 };
            let mut text = String::new();
            loop {
                if j >= c.len() {
                    return Err(format!("line {line}: unterminated string"));
                }
                match c[j] {
                    '\\' => {
                        text.push(c[j]);
                        text.push(at(j + 1));
                        if at(j + 1) == '\n' {
                            line += 1;
                        }
                        j += 2;
                    }
                    '"' => break,
                    other => {
                        if other == '\n' {
                            line += 1;
                        }
                        text.push(other);
                        j += 1;
                    }
                }
            }
            out.push(Token {
                tok: Tok::Str(text),
                line,
            });
            i = j + 1;
            continue;
        }
        // Char literals and lifetimes.
        if ch == '\'' || (ch == 'b' && at(i + 1) == '\'') {
            let j = if ch == '\'' { i + 1 } else { i + 2 };
            if at(j) == '\\' {
                let mut k = j + 2;
                while k < c.len() && c[k] != '\'' {
                    k += 1;
                }
                out.push(Token {
                    tok: Tok::Other,
                    line,
                });
                i = k + 1;
                continue;
            }
            if at(j + 1) == '\'' {
                out.push(Token {
                    tok: Tok::Other,
                    line,
                });
                i = j + 2;
                continue;
            }
            // A lifetime or label: skip the quote and the name.
            let mut k = j;
            while is_ident_char(at(k)) {
                k += 1;
            }
            out.push(Token {
                tok: Tok::Other,
                line,
            });
            i = k.max(j);
            continue;
        }
        if is_ident_start(ch) {
            let mut j = i;
            if ch == 'r' && at(i + 1) == '#' && is_ident_start(at(i + 2)) {
                j = i + 2;
            }
            let begin = j;
            while is_ident_char(at(j)) {
                j += 1;
            }
            out.push(Token {
                tok: Tok::Ident(c[begin..j].iter().collect()),
                line,
            });
            i = j;
            continue;
        }
        if ch.is_ascii_digit() {
            let mut j = i;
            while is_ident_char(at(j)) || (at(j) == '.' && at(j + 1).is_ascii_digit()) {
                j += 1;
            }
            out.push(Token {
                tok: Tok::Other,
                line,
            });
            i = j;
            continue;
        }
        if ch == ':' && at(i + 1) == ':' {
            out.push(Token {
                tok: Tok::Punct("::".into()),
                line,
            });
            i += 2;
            continue;
        }
        out.push(Token {
            tok: Tok::Punct(ch.to_string()),
            line,
        });
        i += 1;
    }
    Ok(out)
}

fn is_ident_start(c: char) -> bool {
    c.is_alphabetic() || c == '_'
}
fn is_ident_char(c: char) -> bool {
    c.is_alphanumeric() || c == '_'
}

fn ident(t: Option<&Token>) -> Option<&str> {
    match t.map(|t| &t.tok) {
        Some(Tok::Ident(s)) => Some(s),
        _ => None,
    }
}
fn punct(t: Option<&Token>, p: &str) -> bool {
    matches!(t.map(|t| &t.tok), Some(Tok::Punct(s)) if s == p)
}

/// `rel` resolved against `dir`, without touching the filesystem, must stay under `top`.
fn inside(top: &Path, dir: &Path, rel: &str) -> bool {
    if Path::new(rel).is_absolute() {
        return false;
    }
    let mut parts: Vec<Component> = Vec::new();
    let joined = dir.join(rel);
    for comp in joined.components() {
        match comp {
            Component::ParentDir => {
                if parts.pop().is_none() {
                    return false;
                }
            }
            Component::CurDir => {}
            other => parts.push(other),
        }
    }
    let resolved: PathBuf = parts.iter().collect();
    // `tools/` holds the team's own tools crate, which is not scanned, so the bot can't reach it.
    resolved.starts_with(top) && !resolved.starts_with(top.join(TOOLS))
}

/// The team's tools crate inside its folder: never scanned or built into the bot, never run in a
/// match. It may use files, threads and the harness for self-play.
pub const TOOLS: &str = "tools";

/// The scan of one source file. `top` is the crate folder; `file` is inside it.
pub fn scan_source(top: &Path, file: &Path, src: &str) -> Vec<String> {
    let name = file.strip_prefix(top).unwrap_or(file).display().to_string();
    let tokens = match tokenize(src) {
        Ok(t) => t,
        Err(e) => return vec![format!("{name}: cannot scan: {e}")],
    };
    let dir = file.parent().unwrap_or(top);
    let mut problems = Vec::new();
    let mut flag = |line: usize, what: String| problems.push(format!("{name}:{line}: {what}"));
    for (i, t) in tokens.iter().enumerate() {
        if let Tok::Str(text) = &t.tok
            && formats_address(text)
        {
            flag(t.line, "`{:p}` is not allowed (memory addresses)".into());
        }
        if punct(Some(t), "*") && matches!(ident(tokens.get(i + 1)), Some("const" | "mut")) {
            flag(
                t.line,
                "raw pointers are not allowed (memory addresses)".into(),
            );
        }
        if punct(Some(t), "&") && ident(tokens.get(i + 1)) == Some("raw") {
            flag(t.line, "`&raw` is not allowed (memory addresses)".into());
        }
        let Tok::Ident(word) = &t.tok else { continue };
        if let Some((_, why)) = BANNED.iter().find(|(b, _)| b == word) {
            flag(t.line, format!("`{word}` is not allowed ({why})"));
        }
        if word.starts_with("Atomic") || word == "atomic" {
            flag(t.line, format!("`{word}` is not allowed (atomics)"));
        }
        if ["std", "core", "alloc"].contains(&word.as_str()) {
            let next = tokens.get(i + 1);
            if ident(next) == Some("as") {
                flag(
                    t.line,
                    format!("`{word} as ...` is not allowed (renaming the standard library)"),
                );
            }
            if punct(next, "::") {
                let after = tokens.get(i + 2);
                match ident(after) {
                    Some(seg) if STD_ALLOWED.contains(&seg) => {}
                    Some(seg) => flag(t.line, format!("`{word}::{seg}` is not allowed")),
                    None if punct(after, "*") => {
                        flag(t.line, format!("`{word}::*` is not allowed"))
                    }
                    None if punct(after, "{") => {
                        // Each first-level item of the group.
                        let mut depth = 0;
                        let mut expect = true;
                        for g in &tokens[i + 2..] {
                            match &g.tok {
                                Tok::Punct(p) if p == "{" => {
                                    depth += 1;
                                    expect = depth == 1;
                                    continue;
                                }
                                Tok::Punct(p) if p == "}" => {
                                    depth -= 1;
                                    if depth == 0 {
                                        break;
                                    }
                                    continue;
                                }
                                Tok::Punct(p) if p == "," && depth == 1 => {
                                    expect = true;
                                    continue;
                                }
                                _ => {}
                            }
                            if expect && depth == 1 {
                                match &g.tok {
                                    Tok::Ident(seg) if STD_ALLOWED.contains(&seg.as_str()) => {}
                                    Tok::Ident(seg) => {
                                        flag(g.line, format!("`{word}::{{{seg}}}` is not allowed"))
                                    }
                                    other => flag(
                                        g.line,
                                        format!("`{word}::{{{other:?}}}` is not allowed"),
                                    ),
                                }
                                expect = false;
                            }
                        }
                    }
                    None => flag(t.line, format!("`{word}::` must name an allowed module")),
                }
            }
        }
        if ["include", "include_str", "include_bytes"].contains(&word.as_str())
            && punct(tokens.get(i + 1), "!")
        {
            let arg = tokens.get(i + 3);
            match (
                punct(tokens.get(i + 2), "(") || punct(tokens.get(i + 2), "["),
                arg.map(|a| &a.tok),
                punct(tokens.get(i + 4), ")") || punct(tokens.get(i + 4), "]"),
            ) {
                (true, Some(Tok::Str(path)), true) => {
                    if !inside(top, dir, path) {
                        flag(
                            t.line,
                            format!("`{word}!(\"{path}\")` reaches outside the crate folder"),
                        );
                    }
                }
                _ => flag(t.line, format!("`{word}!` must take one literal path")),
            }
        }
        if word == "path"
            && punct(tokens.get(i.wrapping_sub(1)), "[")
            && punct(tokens.get(i + 1), "=")
        {
            match tokens.get(i + 2).map(|a| &a.tok) {
                Some(Tok::Str(path)) if inside(top, dir, path) => {}
                Some(Tok::Str(path)) => flag(
                    t.line,
                    format!("`#[path = \"{path}\"]` reaches outside the crate folder"),
                ),
                _ => flag(t.line, "`#[path]` must be a literal".into()),
            }
        }
    }
    problems
}

/// A format string with a `{...:p}` placeholder (any flags or width).
fn formats_address(text: &str) -> bool {
    let mut rest = text;
    while let Some(open) = rest.find('{') {
        rest = &rest[open + 1..];
        if rest.starts_with('{') {
            rest = &rest[1..];
            continue;
        }
        let Some(close) = rest.find('}') else { break };
        if let Some((_, spec)) = rest[..close].split_once(':')
            && spec.ends_with('p')
        {
            return true;
        }
        rest = &rest[close + 1..];
    }
    false
}

/// `#![forbid(unsafe_code)]` as tokens.
fn has_forbid(src: &str) -> bool {
    let Ok(tokens) = tokenize(src) else {
        return false;
    };
    let want = ["#", "!", "[", "forbid", "(", "unsafe_code", ")", "]"];
    tokens.windows(want.len()).any(|w| {
        w.iter().zip(want).all(|(t, s)| match &t.tok {
            Tok::Ident(x) | Tok::Punct(x) => x == s,
            _ => false,
        })
    })
}

struct Manifest {
    package: String,
    lib_name: Option<String>,
}

fn check_manifest(text: &str, problems: &mut Vec<String>) -> Manifest {
    let mut section = String::new();
    let mut package = String::new();
    let mut lib_name = None;
    let allowed_keys = |section: &str| -> &'static [&'static str] {
        match section {
            "package" => &[
                "name",
                "version",
                "edition",
                "publish",
                "rust-version",
                "license",
                "description",
                "authors",
            ],
            "lib" => &["name", "path"],
            _ => &[],
        }
    };
    for (n, raw) in text.lines().enumerate() {
        let line = raw.split('#').next().unwrap_or("").trim();
        if line.is_empty() {
            continue;
        }
        if let Some(name) = line.strip_prefix('[') {
            section = name.trim_end_matches(']').trim().to_owned();
            if !["package", "lib", "dependencies"].contains(&section.as_str()) {
                problems.push(format!(
                    "Cargo.toml:{}: section [{section}] is not allowed",
                    n + 1
                ));
            }
            continue;
        }
        let Some((key, value)) = line.split_once('=') else {
            problems.push(format!("Cargo.toml:{}: cannot read `{line}`", n + 1));
            continue;
        };
        let key = key.trim().trim_matches('"');
        let value = value.trim();
        match section.as_str() {
            "dependencies" => {
                let base = key.split('.').next().unwrap_or(key);
                if !ALLOWED_DEPS.contains(&base) {
                    problems.push(format!("Cargo.toml:{}: dependency `{base}` is not on the allowlist {ALLOWED_DEPS:?}", n + 1));
                }
                if value.contains("package") || value.contains("git") || value.contains("registry")
                {
                    problems.push(format!(
                        "Cargo.toml:{}: dependency `{base}` must be a plain path dependency",
                        n + 1
                    ));
                }
            }
            s => {
                if !allowed_keys(s).contains(&key) {
                    problems.push(format!(
                        "Cargo.toml:{}: key `{key}` in [{s}] is not allowed",
                        n + 1
                    ));
                }
                if s == "package" && key == "name" {
                    package = value.trim_matches('"').to_owned();
                }
                if s == "lib" && key == "name" {
                    lib_name = Some(value.trim_matches('"').to_owned());
                }
                if s == "lib" && key == "path" && value.trim_matches('"') != "src/lib.rs" {
                    problems.push(format!(
                        "Cargo.toml:{}: [lib] path must be src/lib.rs",
                        n + 1
                    ));
                }
            }
        }
    }
    if package.is_empty() {
        problems.push("Cargo.toml: no package name".into());
    }
    Manifest { package, lib_name }
}

fn walk(dir: &Path, out: &mut Vec<PathBuf>, problems: &mut Vec<String>, top: &Path) {
    let Ok(entries) = std::fs::read_dir(dir) else {
        problems.push(format!("cannot read {}", dir.display()));
        return;
    };
    let mut entries: Vec<_> = entries.flatten().collect();
    entries.sort_by_key(|e| e.path());
    for entry in entries {
        let path = entry.path();
        let rel = path
            .strip_prefix(top)
            .unwrap_or(&path)
            .display()
            .to_string();
        let Ok(kind) = entry.file_type() else {
            continue;
        };
        if kind.is_symlink() {
            problems.push(format!("{rel}: symbolic links are not allowed"));
            continue;
        }
        if kind.is_dir() {
            if rel == "target" || rel == TOOLS {
                continue;
            }
            if entry.file_name() == ".cargo" {
                problems.push(format!("{rel}: a .cargo folder is not allowed"));
            }
            walk(&path, out, problems, top);
        } else {
            out.push(path);
        }
    }
}

/// The static checks; returns the crate's library name.
pub fn static_checks(path: &Path) -> Result<String, Vec<String>> {
    let mut problems = Vec::new();
    let top = match path.canonicalize() {
        Ok(p) => p,
        Err(e) => return Err(vec![format!("{}: {e}", path.display())]),
    };
    let manifest_text = std::fs::read_to_string(top.join("Cargo.toml")).unwrap_or_default();
    let manifest = check_manifest(&manifest_text, &mut problems);
    if top.join("build.rs").exists() {
        problems.push("build.rs: build scripts are not allowed".into());
    }
    let lib = top.join("src/lib.rs");
    match std::fs::read_to_string(&lib) {
        Ok(src) => {
            if !has_forbid(&src) {
                problems
                    .push("src/lib.rs: the crate root must have #![forbid(unsafe_code)]".into());
            }
            if !src.contains("fn new_bot") {
                problems.push(
                    "src/lib.rs: no `pub fn new_bot(seed: u64, setup: &BotSetup) -> Box<dyn Bot>`"
                        .into(),
                );
            }
        }
        Err(_) => problems.push("src/lib.rs: missing".into()),
    }
    let mut files = Vec::new();
    walk(&top, &mut files, &mut problems, &top);
    for file in files
        .iter()
        .filter(|f| f.extension().is_some_and(|e| e == "rs"))
    {
        match std::fs::read_to_string(file) {
            Ok(src) => problems.extend(scan_source(&top, file, &src)),
            Err(e) => problems.push(format!("{}: {e}", file.display())),
        }
    }
    if problems.is_empty() {
        Ok(manifest
            .lib_name
            .unwrap_or_else(|| manifest.package.replace('-', "_")))
    } else {
        Err(problems)
    }
}

fn copy_tree(from: &Path, to: &Path, skip: &[&str]) -> std::io::Result<()> {
    std::fs::create_dir_all(to)?;
    for entry in std::fs::read_dir(from)? {
        let entry = entry?;
        let name = entry.file_name();
        if skip.iter().any(|s| name == *s) {
            continue;
        }
        let kind = entry.file_type()?;
        if kind.is_dir() {
            copy_tree(&entry.path(), &to.join(&name), skip)?;
        } else if kind.is_file() {
            std::fs::copy(entry.path(), to.join(&name))?;
        }
    }
    Ok(())
}

/// The whole check: static checks, then the isolated build.
pub fn check(root: &Path, path: &Path, name: &str, keep: bool) -> Result<String, Vec<String>> {
    if !["red", "blue"].contains(&name) {
        return Err(vec![format!("--name must be red or blue, not {name}")]);
    }
    let lib_name = static_checks(path)?;
    // The registry builds `red` and `blue` by those package names.
    let package = static_package(path);
    if package != name {
        return Err(vec![format!(
            "Cargo.toml: the package name must be `{name}`, not `{package}`"
        )]);
    }
    let league = root.join("tools/league");
    let work = std::env::temp_dir().join(format!("league-check-{name}-{}", std::process::id()));
    let fail = |e: String| vec![e];
    let _ = std::fs::remove_dir_all(&work);
    let io = |e: std::io::Error| vec![format!("building the check tree: {e}")];
    for part in ["bramble-engine", "bramble-ghosts", "league-api", "league"] {
        copy_tree(&league.join(part), &work.join(part), &["target"]).map_err(io)?;
    }
    copy_tree(&league.join("vendor"), &work.join("vendor"), &[]).map_err(io)?;
    copy_tree(&league.join(".cargo"), &work.join(".cargo"), &[]).map_err(io)?;
    std::fs::copy(league.join("Cargo.lock"), work.join("Cargo.lock")).map_err(io)?;
    copy_tree(path, &work.join("bots").join(name), &["target", TOOLS]).map_err(io)?;
    // The team crate's league-api path, wherever the crate lived before.
    let manifest =
        std::fs::read_to_string(work.join("bots").join(name).join("Cargo.toml")).map_err(io)?;
    let manifest: String = manifest
        .lines()
        .map(|l| {
            if l.trim_start().starts_with("league-api") {
                "league-api = { path = \"../../league-api\" }".to_owned()
            } else {
                l.to_owned()
            }
        })
        .collect::<Vec<_>>()
        .join("\n");
    std::fs::write(
        work.join("bots").join(name).join("Cargo.toml"),
        manifest + "\n",
    )
    .map_err(io)?;
    std::fs::create_dir_all(work.join("bots/registry/src")).map_err(io)?;
    std::fs::write(
        work.join("bots/registry/Cargo.toml"),
        format!(
            "[package]\nname = \"league-bots\"\nversion = \"0.1.0\"\nedition.workspace = true\nrust-version.workspace = true\nlicense.workspace = true\n\n[dependencies]\nleague-api = {{ path = \"../../league-api\" }}\n{package} = {{ path = \"../{name}\" }}\n"
        ),
    )
    .map_err(io)?;
    std::fs::write(
        work.join("bots/registry/src/lib.rs"),
        format!("use league_api::Factory;\npub fn factories() -> Vec<(&'static str, Factory)> {{\n    vec![(\"{name}\", {lib_name}::new_bot)]\n}}\n"),
    )
    .map_err(io)?;
    let root_manifest = std::fs::read_to_string(league.join("Cargo.toml")).map_err(io)?;
    let shared = root_manifest
        .split_once("[workspace.package]")
        .map(|(_, rest)| rest)
        .unwrap_or("");
    std::fs::write(
        work.join("Cargo.toml"),
        format!(
            "[workspace]\nmembers = [\"bramble-engine\", \"bramble-ghosts\", \"league-api\", \"league\", \"bots/registry\", \"bots/{name}\"]\nresolver = \"3\"\n\n[workspace.package]{shared}"
        ),
    )
    .map_err(io)?;
    let cargo = |args: &[&str]| -> Result<String, Vec<String>> {
        let out = Command::new("cargo")
            .args(args)
            .current_dir(&work)
            .env("CARGO_BUILD_JOBS", "2")
            .env("CARGO_TARGET_DIR", work.join("target"))
            .output()
            .map_err(|e| fail(format!("cargo: {e}")))?;
        let text = String::from_utf8_lossy(&out.stderr).into_owned();
        if out.status.success() {
            Ok(text)
        } else {
            let tail: Vec<&str> = text
                .lines()
                .filter(|l| l.starts_with("error") || l.contains("-->"))
                .take(12)
                .collect();
            Err(fail(format!(
                "cargo {} failed: {}",
                args.join(" "),
                tail.join(" | ")
            )))
        }
    };
    // Only the workspace's own entries change in the lock; no outside crate can be added.
    cargo(&["update", "--offline", "--workspace"])?;
    cargo(&[
        "build",
        "--offline",
        "--locked",
        "--release",
        "-p",
        "league",
    ])?;
    let listed = Command::new(work.join("target/release/league"))
        .arg("bots")
        .output()
        .map_err(|e| fail(e.to_string()))?;
    let names = String::from_utf8_lossy(&listed.stdout).into_owned();
    if !names.lines().any(|l| l == name) {
        return Err(fail(format!("the built harness does not list `{name}`")));
    }
    if !keep {
        let _ = std::fs::remove_dir_all(&work);
    }
    Ok(format!(
        "static checks clean; built offline and locked with only the engine, API, harness and this crate (registered as `{name}`){}",
        if keep {
            format!("; tree kept at {}", work.display())
        } else {
            String::new()
        }
    ))
}

fn static_package(path: &Path) -> String {
    let text = std::fs::read_to_string(path.join("Cargo.toml")).unwrap_or_default();
    let mut problems = Vec::new();
    check_manifest(&text, &mut problems).package
}

#[cfg(test)]
mod tests {
    use super::*;

    fn scan(src: &str) -> Vec<String> {
        scan_source(Path::new("/crate"), Path::new("/crate/src/lib.rs"), src)
    }

    #[test]
    fn clean_code_passes() {
        let src = r#"
            #![forbid(unsafe_code)]
            use std::collections::HashMap;
            use std::{cmp::Ordering, rc::Rc};
            // static in a comment, std::fs in a comment
            fn f<'a>(x: &'a str) -> &'static str { let _s = "static std::thread"; let _c = 'x'; "" }
            const TABLE: &[u8] = include_bytes!("../data/table.bin");
            fn g(b: &mut u8, c: u8) -> String { *b *= c; let _m = &mut *b; let _d = c * *b; format!("{:?} {c:>5} {{:p}} {}", c, *b) }
        "#;
        assert!(scan(src).is_empty(), "{:?}", scan(src));
    }

    #[test]
    fn banned_items_are_found() {
        for (src, want) in [
            ("static X: u32 = 1;", "static"),
            ("static mut X: u32 = 1;", "static"),
            ("thread_local! { }", "thread_local"),
            ("use std::sync::OnceLock;", "std::sync"),
            ("use std::sync::atomic::AtomicU64;", "std::sync"),
            ("fn f() { std::thread::spawn(|| {}); }", "std::thread"),
            ("use std::{collections, fs};", "fs"),
            ("use std::*;", "std::*"),
            ("use ::std as s;", "renaming"),
            ("fn f() { let _ = std::time::Instant::now(); }", "std::time"),
            ("fn f() { let _ = env!(\"HOME\"); }", "environment"),
            ("extern crate core as c;", "extern"),
            ("#[unsafe(no_mangle)] fn f() {}", "unsafe"),
            ("fn f() { unsafe { } }", "unsafe"),
            ("include!(\"../../red/src/lib.rs\");", "outside"),
            (
                "const X: &str = include_str!(concat!(\"a\", \"b\"));",
                "literal",
            ),
            ("#[path = \"../../red/lib.rs\"] mod m;", "outside"),
            ("use core::r#mem;\nuse std::r#process;", "std::process"),
            (
                "fn f() { let _ = league_api::harness::thread_cpu_ns(); }",
                "harness",
            ),
            (
                "fn f(x: &u8) -> String { format!(\"{:p}\", x) }",
                "memory addresses",
            ),
            (
                "fn f(x: &u8) -> String { format!(\"{x:#018p}\") }",
                "memory addresses",
            ),
            (
                "fn f(x: &u8) -> usize { x as *const u8 as usize }",
                "memory addresses",
            ),
            (
                "fn f(x: &mut u8) { let _ = x as *mut u8; }",
                "memory addresses",
            ),
            ("fn f(x: u8) { let _ = &raw const x; }", "memory addresses"),
            (
                "fn f(v: Vec<u8>) { let _ = v.as_ptr(); }",
                "memory addresses",
            ),
            (
                "fn f() { let _ = Box::leak(Box::new(1)); }",
                "memory addresses",
            ),
            (
                "fn f(r: std::rc::Rc<u8>) { let _ = std::rc::Rc::into_raw(r); }",
                "memory addresses",
            ),
            ("use std::ptr;", "std::ptr"),
            ("include!(\"../tools/src/main.rs\");", "outside"),
            ("#[path = \"../tools/src/main.rs\"] mod t;", "outside"),
        ] {
            let found = scan(src);
            assert!(found.iter().any(|p| p.contains(want)), "{src}: {found:?}");
        }
    }

    #[test]
    fn manifest_rules() {
        let mut p = Vec::new();
        check_manifest(
            "[package]\nname = \"x\"\nbuild = \"b.rs\"\n[build-dependencies]\ncc = \"1\"\n[dependencies]\nserde = \"1\"\nleague-api = { path = \"../../league-api\" }\n",
            &mut p,
        );
        for want in ["`build`", "[build-dependencies]", "`serde`"] {
            assert!(p.iter().any(|x| x.contains(want)), "{want}: {p:?}");
        }
        assert!(
            !p.iter().any(|x| x.contains("dependency `league-api`")),
            "{p:?}"
        );
    }
}
