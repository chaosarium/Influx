from flask import Flask, request, render_template
import argparse
import stanza

app = Flask(__name__)
context = {
    'loaded_pipelines': {},
}



def tokenise_text(text: str, language: str) -> tuple[str, int, int, list[list[list[dict[str, str|int]]]]]:
    if not language in context['loaded_pipelines']:
        nlp = stanza.Pipeline(lang=language, processors='tokenize, lemma', model_dir=f"{context['influx_path']}/stanza_resources/", logging_level='WARN')
        context['loaded_pipelines'][language] = nlp
    else:
        nlp = context['loaded_pipelines'][language]
        
    doc = nlp(text)

    constituents = []
    for sentence in doc.sentences:
        constituents.append([token.to_dict() for token in sentence.tokens])
    
    print(constituents)
        
    return {
        'text': doc.text,
        'num_tokens': doc.num_tokens,
        'num_sentences': len(doc.sentences),
        'constituents': constituents,
    }



@app.route("/")
def root_handler():
    port = context['port']
    return f"Hello, World! Running on port {port}" 

# post is a workaroudn for large incoming data
@app.route('/tokeniser/<lang_code>', methods=["POST"])
def tokeniser_handler(lang_code):
    data = request.get_json()
    text = data.get('text', '')
    print(f'Received text: {text}, lang_code: {lang_code}')
    return tokenise_text(text, lang_code)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Arguments for NLP server")
    parser.add_argument('--port', type=int, help='The port to run the NLP server', required=True)
    parser.add_argument('--influx_path', type=str, help='The path to the influx content directory', required=True)
    args = parser.parse_args()
    
    context['port'] = args.port
    context['influx_path'] = args.influx_path
    app.run(host='127.0.0.1', port=args.port)