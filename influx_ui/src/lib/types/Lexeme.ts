import type { Token } from './Token';
import type { Phrase } from './Phrase';


export type Lexeme = {
    "type": "Token";
    value: Token;
} | {
    "type": "Phrase";
    value: Phrase;
};
