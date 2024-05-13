import { Option } from './types/Option'
import type { Token } from './types/Token'
import type { Phrase } from './types/Phrase'
import type { SentenceConstituent } from './types/SentenceConstituent';
import type { Lexeme } from './types/Lexeme';
import type { DocumentSlice } from './types/Aliases';

export function try_access(obj: any, key: string): Option<any> {
    let res = obj[key];
    if (res === undefined) {
        return Option.None();
    }
    return Option.Some(obj[key]);
}

export function try_key(obj: any, key: Option<string>): Option<any> {
    if (key.is_none()) {
        return Option.None();
    }
    return try_access(obj, key.unwrap());
}

export function try_lookup(token_dict: Record<string, Token>, phrase_dict: Record<string, Phrase>, constituent: Option<SentenceConstituent>): Option<Lexeme> {
    if (constituent.is_none()) {
        return Option.None();
    }
    let c = constituent.unwrap();
    if (c.type === "SingleToken" || c.type === "SubwordToken" || c.type === "CompositToken") {
        return Option.Some({ type: "Token", value: token_dict[c.orthography] });
    } else if (c.type === "Whitespace") {
        return Option.None();  
    } else if (c.type === "PhraseToken") {
        return Option.Some({ type: "Phrase", value: phrase_dict[c.normalised_orthography] });
    } else {
        return Option.None();
    }
}

export function is_cst_in_slice(slice: DocumentSlice, con: SentenceConstituent): boolean {
    // console.log(slice, con);
    let ss = slice[0][0];
    let es = slice[1][0];
    let st = slice[0][1];
    let et = slice[1][1];
    let sc = slice[0][2];
    let ec = slice[1][2];
    switch (con.type) {
        case "SingleToken":
        case "SubwordToken":
            return ((con.sentence_id == ss && con.id >= st) || con.sentence_id > ss) && ((con.sentence_id == es && con.id <= et) || con.sentence_id < es);
        case "PhraseToken":
        case "CompositToken":
        case "Whitespace":
            return con.start_char >= sc && con.end_char <= ec;
    }
}