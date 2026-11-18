//! Godot 4.7.2 `JSON.stringify(value)` defaults: compact, sorted keys, 15 digits.
//!
//! Number and escaping logic follows `core/io/json.cpp` and `core/string/ustring.cpp`
//! at https://github.com/godotengine/godot/tree/4.7.2-stable.
//! Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md).
//! Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.
//!
//! Permission is hereby granted, free of charge, to any person obtaining a copy
//! of this software and associated documentation files (the "Software"), to deal
//! in the Software without restriction, including without limitation the rights
//! to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//! copies of the Software, and to permit persons to whom the Software is
//! furnished to do so, subject to the following conditions:
//!
//! The above copyright notice and this permission notice shall be included in
//! all copies or substantial portions of the Software.
//!
//! THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//! IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//! FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//! AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//! LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//! OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//! THE SOFTWARE.
use std::{collections::HashSet, fmt::Write};

use crate::Variant;

/// Serialize without applying RecordState's integral-float canonicalization.
pub fn stringify(value: &Variant) -> String {
    let mut out = String::new();
    write_value(value, &mut out, &mut HashSet::new(), 0);
    out
}

fn write_value(value: &Variant, out: &mut String, markers: &mut HashSet<usize>, depth: usize) {
    if depth > 1024 {
        out.push_str("...");
        return;
    }
    match value {
        Variant::Nil => out.push_str("null"),
        Variant::Bool(flag) => out.push_str(if *flag { "true" } else { "false" }),
        Variant::Int(number) => write!(out, "{number}").expect("writing to a String cannot fail"),
        Variant::Float(number) => out.push_str(&format_float(*number)),
        Variant::String(text) => write_string(text, out),
        Variant::Array(array) => {
            let array = array.borrow();
            let marker = (&*array as *const Vec<Variant>) as usize;
            if markers.contains(&marker) {
                out.push_str("\"[...]\"");
                return;
            }
            out.push('[');
            markers.insert(marker);
            for (i, entry) in array.iter().enumerate() {
                if i > 0 {
                    out.push(',');
                }
                write_value(entry, out, markers, depth + 1);
            }
            out.push(']');
            markers.remove(&marker);
        }
        Variant::Dictionary(dictionary) => {
            let dictionary = dictionary.borrow();
            let marker = (&*dictionary as *const indexmap::IndexMap<String, Variant>) as usize;
            if markers.contains(&marker) {
                out.push_str("\"{...}\"");
                return;
            }
            out.push('{');
            markers.insert(marker);
            let mut entries: Vec<_> = dictionary.iter().collect();
            super::godot_sort::sort_by(&mut entries, |a, b| a.0 < b.0);
            for (i, (key, value)) in entries.into_iter().enumerate() {
                if i > 0 {
                    out.push(',');
                }
                write_string(key, out);
                out.push(':');
                write_value(value, out, markers, depth + 1);
            }
            out.push('}');
            markers.remove(&marker);
        }
    }
}

fn write_string(text: &str, out: &mut String) {
    out.push('"');
    let mut start = 0;
    for (index, byte) in text.bytes().enumerate() {
        let escaped = match byte {
            b'\\' => "\\\\",
            b'\x08' => "\\b",
            b'\x0c' => "\\f",
            b'\n' => "\\n",
            b'\r' => "\\r",
            b'\t' => "\\t",
            b'\x0b' => "\\v",
            b'"' => "\\\"",
            _ => continue,
        };
        // Only ASCII escape bytes split slices, so every boundary is valid UTF-8.
        // All other bytes, including Godot's unescaped controls, pass through verbatim.
        out.push_str(&text[start..index]);
        out.push_str(escaped);
        start = index + 1;
    }
    out.push_str(&text[start..]);
    out.push('"');
}

fn format_float(number: f64) -> String {
    if number.is_nan() {
        return "null".into();
    }
    if number == f64::INFINITY {
        return "1e99999".into();
    }
    if number == f64::NEG_INFINITY {
        return "-1e99999".into();
    }
    if number == 0.0 {
        return "0.0".into();
    }
    let magnitude = number.abs().log10();
    let precision = (14 - magnitude.floor() as i32).clamp(1, 32) as usize;
    // String::num uses snprintf("%.*lf") (round to nearest, ties to even).
    let mut formatted = format!("{number:.precision$}");
    // Godot String::num's buffer has 325 bytes including the terminator.
    formatted.truncate(formatted.len().min(324));
    if formatted.contains('.') {
        while formatted.ends_with('0') {
            formatted.pop();
        }
        if formatted.ends_with('.') {
            formatted.push('0');
        }
    }
    formatted
}

/// Record JSON is standard JSON. As with Godot, every parsed number is a Float,
/// and malformed input and JSON `null` both return Nil. The parser preserves key order.
/// Godot's additional acceptance of trailing commas/raw control characters is handled
/// by a small token parser below, rather than changing the incoming text first.
pub fn parse_string(text: &str) -> Variant {
    Parser::new(text).parse().unwrap_or(Variant::Nil)
}

struct Parser<'a> {
    text: &'a str,
    pos: usize,
}
impl<'a> Parser<'a> {
    fn new(text: &'a str) -> Self {
        Self { text, pos: 0 }
    }
    fn peek(&self) -> Option<char> {
        self.text[self.pos..].chars().next()
    }
    fn take(&mut self) -> Option<char> {
        let c = self.peek()?;
        self.pos += c.len_utf8();
        Some(c)
    }
    fn whitespace(&mut self) {
        while self.peek().is_some_and(|c| c <= ' ') {
            self.take();
        }
    }
    fn parse(mut self) -> Option<Variant> {
        let result = self.value(0)?;
        self.whitespace();
        // JSON::_parse_string requires EOF after the single root value.
        if self.peek().is_some_and(|c| c != '\0') {
            None
        } else {
            Some(result)
        }
    }
    fn value(&mut self, depth: usize) -> Option<Variant> {
        if depth > 1024 {
            return None;
        }
        self.whitespace();
        match self.peek()? {
            '"' => Some(Variant::String(self.string()?)),
            '[' => {
                self.take();
                let mut values = Vec::new();
                self.whitespace();
                if self.peek() == Some(']') {
                    self.take();
                    return Some(Variant::array(values));
                }
                loop {
                    values.push(self.value(depth + 1)?);
                    self.whitespace();
                    match self.take()? {
                        ']' => break,
                        ',' => {
                            self.whitespace();
                            if self.peek() == Some(']') {
                                self.take();
                                break;
                            }
                        }
                        _ => return None,
                    }
                }
                Some(Variant::array(values))
            }
            '{' => {
                self.take();
                let mut values = indexmap::IndexMap::new();
                self.whitespace();
                if self.peek() == Some('}') {
                    self.take();
                    return Some(Variant::dictionary(values));
                }
                loop {
                    self.whitespace();
                    let key = self.string()?;
                    self.whitespace();
                    if self.take()? != ':' {
                        return None;
                    }
                    values.insert(key, self.value(depth + 1)?);
                    self.whitespace();
                    match self.take()? {
                        '}' => break,
                        ',' => {
                            self.whitespace();
                            if self.peek() == Some('}') {
                                self.take();
                                break;
                            }
                        }
                        _ => return None,
                    }
                }
                Some(Variant::dictionary(values))
            }
            c if c.is_ascii_alphabetic() => {
                let start = self.pos;
                while self.peek().is_some_and(|c| c.is_ascii_alphabetic()) {
                    self.take();
                }
                match &self.text[start..self.pos] {
                    "null" => Some(Variant::Nil),
                    "true" => Some(Variant::Bool(true)),
                    "false" => Some(Variant::Bool(false)),
                    _ => None,
                }
            }
            '-' | '0'..='9' => self.number().map(Variant::Float),
            _ => None,
        }
    }
    fn string(&mut self) -> Option<String> {
        if self.take()? != '"' {
            return None;
        }
        let mut result = String::new();
        loop {
            match self.take()? {
                '\0' => return None,
                '"' => return Some(result),
                '\\' => match self.take()? {
                    'b' => result.push('\u{8}'),
                    't' => result.push('\t'),
                    'n' => result.push('\n'),
                    'f' => result.push('\u{c}'),
                    'r' => result.push('\r'),
                    c @ ('"' | '\\' | '/') => result.push(c),
                    'u' => {
                        let mut code = self.hex4()?;
                        if (0xd800..=0xdbff).contains(&code) {
                            if self.take()? != '\\' || self.take()? != 'u' {
                                return None;
                            }
                            let trail = self.hex4()?;
                            if !(0xdc00..=0xdfff).contains(&trail) {
                                return None;
                            }
                            code = 0x10000 + ((code - 0xd800) << 10) + trail - 0xdc00;
                        }
                        if code == 0 {
                            result.push('\u{fffd}');
                        } else {
                            result.push(char::from_u32(code)?);
                        }
                    }
                    _ => return None,
                },
                c => result.push(c),
            }
        }
    }
    fn hex4(&mut self) -> Option<u32> {
        let mut code = 0;
        for _ in 0..4 {
            code = (code << 4) + self.take()?.to_digit(16)?;
        }
        Some(code)
    }
    fn number(&mut self) -> Option<f64> {
        let start = self.pos;
        if self.peek() == Some('-') {
            self.take();
        }
        while self.peek().is_some_and(|c| c.is_ascii_digit()) {
            self.take();
        }
        if self.peek() == Some('.') {
            self.take();
            while self.peek().is_some_and(|c| c.is_ascii_digit()) {
                self.take();
            }
        }
        if self.peek().is_some_and(|c| c == 'e' || c == 'E') {
            let exponent = self.pos;
            self.take();
            if self.peek().is_some_and(|c| c == '+' || c == '-') {
                self.take();
            }
            let digits = self.pos;
            while self.peek().is_some_and(|c| c.is_ascii_digit()) {
                self.take();
            }
            if digits == self.pos {
                self.pos = exponent;
            }
        }
        self.text[start..self.pos].parse().ok()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{Dictionary, ToState};

    #[test]
    fn godot_json_four_edge_oracles() {
        let expected = parse_string(include_str!("../../../gd/util_vectors.json"))
            .as_dict()
            .get("json")
            .as_dict();
        let escapes = Variant::from("\\\"\u{8}\u{c}\n\r\t\u{b}/ café ⛄ 🦔 \u{1}");
        assert_eq!(stringify(&escapes), expected.get("escapes").as_text());
        let unicode_keys = crate::state_dict! { "🦔" => &1_i64, "é" => &2_i64, "z" => &3_i64, "⛄" => &4_i64, "a" => &5_i64 };
        assert_eq!(
            stringify(&unicode_keys),
            expected.get("unicode_keys").as_text()
        );
        let nested = parse_string(r#"{"z":[{},[],{"a":null,"b":false}],"a":{}}"#);
        assert_eq!(stringify(&nested), expected.get("nested").as_text());
        let numbers = Variant::array(vec![
            Variant::Int(0),
            Variant::Int(-1),
            Variant::Int(i64::MIN),
            Variant::Int(i64::MAX),
            Variant::Float(0.0),
            Variant::Float(-0.0),
            Variant::Float(1.0),
            Variant::Float(-1.0),
            Variant::Float(0.1),
            Variant::Float(-123.456),
            Variant::Float(1.2345678901234567),
            Variant::Float(1e20),
            Variant::Float(-1e20),
            Variant::Float(1e-20),
            Variant::Float(-1e-35),
            Variant::Float(1e-100),
            Variant::Float(1e300),
            Variant::Float(f64::INFINITY),
            Variant::Float(f64::NEG_INFINITY),
        ]);
        assert_eq!(stringify(&numbers), expected.get("numbers").as_text());
        assert_eq!(stringify(&Variant::Float(f64::NAN)), "null");
    }

    #[test]
    fn borrowed_dictionary_entries_match_cloned_key_serialization() {
        // More than the SortArray threshold, including escaped/Unicode keys and
        // repeated prefixes, exercises both its insertion-sort and introsort paths.
        let dictionary = Dictionary::new();
        for i in (0..40).rev() {
            dictionary.insert(format!("key:{i}\n🦔"), Variant::Float(i as f64 + 0.25));
        }
        dictionary.insert("é", parse_string(r#"{"z":[null,true],"a":"\t"}"#));
        dictionary.insert("\"", Variant::from("escaped\nvalue"));
        dictionary.insert("", Variant::Int(i64::MIN));
        let expected = {
            let entries = dictionary.borrow();
            let mut keys: Vec<String> = entries.keys().cloned().collect();
            super::super::godot_sort::sort(&mut keys);
            let fields: Vec<_> = keys
                .iter()
                .map(|key| {
                    format!(
                        "{}:{}",
                        stringify(&Variant::from(key.clone())),
                        stringify(&entries[key])
                    )
                })
                .collect();
            format!("{{{}}}", fields.join(","))
        };
        assert_eq!(stringify(&Variant::Dictionary(dictionary)), expected);
    }

    #[test]
    fn string_slices_preserve_unicode_and_raw_controls_at_escape_boundaries() {
        let text = "🦔café\\道\né\t☃\u{b}終\"\u{8}\u{c}\r\0\u{1}\u{7}\u{1f}";
        assert_eq!(
            stringify(&Variant::from(text)),
            "\"🦔café\\\\道\\né\\t☃\\v終\\\"\\b\\f\\r\0\u{1}\u{7}\u{1f}\""
        );
        assert_eq!(stringify(&Variant::from("")), "\"\"");
        assert_eq!(stringify(&Variant::from("🦔道é☃")), "\"🦔道é☃\"");
    }

    #[test]
    fn godot_parse_preserves_insertion_order_and_float_numbers() {
        let parsed = parse_string(r#"{"z":1,"a":-2.5,"z":3,"nested":[4,],}"#).as_dict();
        assert_eq!(
            parsed.borrow().keys().cloned().collect::<Vec<_>>(),
            vec!["z", "a", "nested"]
        );
        assert_eq!(parsed.get("z"), Variant::Float(3.0));
        assert_eq!(
            parsed.get("nested").as_array().get(0),
            Some(Variant::Float(4.0))
        );
        assert_eq!(parse_string(r#""\ud83e\udd94""#), Variant::from("🦔"));
        assert_eq!(parse_string("not JSON"), Variant::Nil);
        assert_eq!(parse_string("true ignored"), Variant::Nil);
        assert_eq!(
            stringify(&parsed.to_state()),
            r#"{"a":-2.5,"nested":[4],"z":3}"#
        );
    }

    #[test]
    fn godot_json_shared_containers_and_cycles() {
        let dict = Dictionary::new();
        dict.insert("self", Variant::Dictionary(dict.clone()));
        assert_eq!(stringify(&Variant::Dictionary(dict)), r#"{"self":"{...}"}"#);
        let shared = crate::Array::from(vec![Variant::from("x")]);
        let value = Variant::array(vec![Variant::Array(shared.clone()), Variant::Array(shared)]);
        assert_eq!(stringify(&value), r#"[["x"],["x"]]"#);
    }
}
