---
title: 'Very long text on transformer'
doc_type: 'Text'
tags: ['tag1', 'tag2']
date_created: '2022-11-28T12:45:59.324310806Z'
date_modified: '2023-11-28T12:45:59.324310806Z'
---

(from wikipedia)

"Transformer architecture" redirects here. For the design of electrical transformers, see Transformer.

A transformer is a deep learning architecture developed by Google and based on the multi-head attention mechanism, proposed in a 2017 paper "Attention Is All You Need".[1] Text is converted to numerical representations called tokens, and each token is converted into a vector via looking up from a word embedding table.[1] At each layer, each token is then contextualized within the scope of the context window with other (unmasked) tokens via a parallel multi-head attention mechanism allowing the signal for key tokens to be amplified and less important tokens to be diminished. The transformer paper, published in 2017, is based on the softmax-based attention mechanism proposed by Bahdanau et. al. in 2014 for machine translation,[2][3] and the Fast Weight Controller, similar to a transformer, proposed in 1992.[4][5][6]

Transformers have the advantage of having no recurrent units, and therefore require less training time than earlier recurrent neural architectures such as long short-term memory (LSTM).[7] Later variations have been widely adopted for training large language models (LLM) on large (language) datasets, such as the Wikipedia corpus and Common Crawl.[8]

This architecture is now used not only in natural language processing and computer vision,[citation needed] but also in audio,[9] multi-modal processing and robotics.[10] It has also led to the development of pre-trained systems, such as generative pre-trained transformers (GPTs)[11] and BERT[12] (Bidirectional Encoder Representations from Transformers).
Timeline of natural language processing models

- In 1990, the Elman network, using a recurrent neural network, encoded each word in a training set as a vector, called a word embedding, and the whole vocabulary as a vector database, allowing it to perform such tasks as sequence-predictions that are beyond the power of a simple multilayer perceptron. A shortcoming of the static embeddings was that they didn't differentiate between multiple meanings of same-spelt words.[13]
- In 1992, the Fast Weight Controller was published by Jürgen Schmidhuber.[4] It learns to answer queries by programming the attention weights of another neural network through outer products of key vectors and value vectors called FROM and TO. The Fast Weight Controller was later shown to be equivalent to the unnormalized linear Transformer.[6][5][14][15] The terminology "learning internal spotlights of attention" was introduced in 1993.[16]
- In 1993, the IBM alignment models were used for statistical machine translation.[17]
- In 1997, a precursor of large language model, using recurrent neural networks, such as long short-term memory, was proposed.
- In 2001, a one-billion-word large text corpus, scraped from the Internet, referred to as "very very large" at the time, was used for word disambiguation.[18]
- In 2012, AlexNet demonstrated the effectiveness of large neural networks for image recognition, encouraging large artificial neural networks approach instead of older, statistical approaches.
- In 2014, a 380M-parameter seq2seq model for machine translation using two Long short-term Memory (LSTMs) networks was proposed by Sutskever at al.[19] The architecture consists of two parts. The encoder is an LSTM that takes in a sequence of tokens and turns it into a vector. The decoder is another LSTM that converts the vector into a sequence of tokens.
- In 2014, gating proved to be useful in a 130M-parameter seq2seq model, which used a simplified gated recurrent units (GRUs). Bahdanau et al[20] showed that GRUs are neither better nor worse than gated LSTMs.[21][22]
- In 2014, Bahdanau et al.[23] improved the previous seq2seq model by using an "additive" kind of attention mechanism in-between two LSTM networks. It was, however, not yet the parallelizable (scaled "dot product") kind of attention, later proposed in the 2017 transformer paper.
- In 2015, the relative performance of Global and Local (windowed) attention model architectures were assessed by Luong et al, a mixed attention architecture found to improve on the translations offered by Bahdanau's architecture, while the use of a local attention architecture reduced translation time.[24]
- In 2016, Google Translate gradually replaced the older statistical machine translation approach with the newer neural-networks-based approach that included a seq2seq model combined by LSTM and the "additive" kind of attention mechanism. They achieved a higher level of performance than the statistical approach, which took ten years to develop, in only nine months.[25][26]
- In 2017, the original (100M-sized) encoder-decoder transformer model with a faster (parallelizable or decomposable) attention mechanism was proposed in the "Attention is all you need" paper. As the model had difficulties converging, it was suggested that the learning rate should be linearly scaled up from 0 to maximal value for the first part of the training (i.e. 2% of the total number of training steps). The intent of the transformer model is to take a seq2seq model and remove its recurrent neural networks, but preserve its additive attention mechanism.[1]
- In 2018, in the ELMo paper, an entire sentence was processed before an embedding vector was assigned to each word in the sentence. A bi-directional LSTM was used to calculate such, deep contextualized embeddings for each word, improving upon the line of research from bag of words and word2vec.
- In 2018, an encoder-only transformer was used in the (more than 1B-sized) BERT model, improving upon ELMo.[27]
- In 2020, vision transformer[28] and speech-processing convolution-augmented transformer[29] outperformed recurrent neural networks, previously used for vision and speech.
- In 2020, difficulties with converging the original transformer were solved by normalizing layers before (instead of after) multiheaded attention by Xiong et al. This is called pre-LN Transformer.[30]
- In 2023, uni-directional ("autoregressive") transformers were being used in the (more than 100B-sized) GPT-3 and other OpenAI GPT models.[31][32]

Predecessors

Before transformers, predecessors of attention mechanism were added to gated recurrent neural networks, such as LSTMs and gated recurrent units (GRUs), which processed datasets sequentially. Dependency on previous token computations prevented them from being able to parallelize the attention mechanism. In 1992, fast weight controller was proposed as an alternative to recurrent neural networks that can learn "internal spotlights of attention".[16][4] In theory, the information from one token can propagate arbitrarily far down the sequence, but in practice the vanishing-gradient problem leaves the model's state at the end of a long sentence without precise, extractable information about preceding tokens.

The performance of old models was enhanced by adding an attention mechanism, which allowed a model to access any preceding point along the sequence. The attention layer weighs all previous states according to a learned measure of relevance, providing relevant information about far-away tokens. This proved to be especially useful in language translation, where far-away context can be essential for the meaning of a word in a sentence. The state vector has been accessible only after the last English word was processed while, for example, translating it from French by a LSTM model. Although in theory such a vector retains the information about the whole original sentence, in practice the information is poorly preserved. If an attention mechanism is added, the decoder is given access to the state vectors of every input word, not just the last, and can learn attention weights that dictate how much to attend to each input state vector. The augmentation of seq2seq models with the attention mechanism was first implemented in the context of machine translation by Bahdanau, Cho, and Bengio in 2014.[2][3]
Decomposable attention

In 2016, highly parallelizable decomposable attention was successfully combined with a feedforward network.[33] This indicated that attention mechanisms were powerful in themselves and that sequential recurrent processing of data was not necessary to achieve the quality gains of recurrent neural networks with attention. In 2017, Vaswani et al. also proposed replacing recurrent neural networks with self-attention and started the effort to evaluate that idea.[1] Transformers, using an attention mechanism, processing all tokens simultaneously, calculated "soft" weights between them in successive layers. Since the attention mechanism only uses information about other tokens from lower layers, it can be computed for all tokens in parallel, which leads to improved training speed.
Methods for stabilizing training

The plain transformer architecture had difficulty converging. In the original paper[1] the authors recommended using learning rate warmup. That is, the learning rate should linearly scale up from 0 to maximal value for the first part of the training (usually recommended to be 2% of the total number of training steps), before decaying again.

A 2020 paper found that using layer normalization before (instead of after) multiheaded attention and feedforward layers stabilizes training, not requiring learning rate warmup.[30]
Pretrain-finetune

Transformers typically undergo self-supervised learning involving unsupervised pretraining followed by supervised fine-tuning. Pretraining is typically done on a larger dataset than fine-tuning, due to the limited availability of labeled training data. Tasks for pretraining and fine-tuning commonly include:

    language modeling[12]
    next-sentence prediction[12]
    question answering[8]
    reading comprehension
    sentiment analysis[1]
    paraphrasing[1]

The T5 transformer paper[34] documents a large number of pretraining tasks. Some examples are:

    restoring corrupted text: Thank you <X> me to your party <Y> week. -> <X> for inviting <Y> last <Z> where the <Z> means "end of output".
    translation: translate English to German: That is good. -> Das ist gut..
    judging the grammatical acceptability of a sentence (CoLA sentence): The course is jumping well. -> not acceptable .

The transformer has had great success in natural language processing (NLP), for example the tasks of machine translation and time series prediction. Many large language models such as GPT-2, GPT-3, GPT-4, Claude, BERT, XLNet, RoBERTa and ChatGPT demonstrate the ability of transformers to perform a wide variety of such NLP-related tasks, and have the potential to find real-world applications. These may include:

    machine translation
    document summarization
    document generation
    named entity recognition (NER)[35]
    biological sequence analysis
    writing computer code based on requirements expressed in natural language.
    video understanding.

In addition to the NLP applications, it has also been successful in other fields, such as computer vision, or the protein folding applications (such as AlphaFold).

As an illustrative example, Ithaca is an encoder-only transformer with three output heads. It takes as input ancient Greek inscription as sequences of characters, but with illegible characters replaced with "-". Its three output heads respectively outputs probability distributions over Greek characters, location of inscription, and date of inscription.[36]

The transformer model has been implemented in standard deep learning frameworks such as TensorFlow and PyTorch.

Transformers is a library produced by Hugging Face that supplies transformer-based architectures and pretrained models.[11]

An illustration of main components of the transformer model from the original paper, where layer normalization was performed after multiheaded attention. In a 2020 paper it was found that placing the layer normalization in front of the multiheaded attention (instead of after) improves the training stability.[30]
An illustration of main components of the transformer model from the original paper, where layer normalization was performed after multiheaded attention. In a 2020 paper it was found that placing the layer normalization in front of the multiheaded attention (instead of after) improves the training stability.[30]

All transformers have the same primary components:

    Tokenizers, which convert text into tokens.
    A single embedding layer, which converts tokens and positions of the tokens into vector representations.
    Transformer layers, which carry out repeated transformations on the vector representations, extracting more and more linguistic information. These consist of alternating attention and feedforward layers.
    (optional) Un-embedding layer, which converts the final vector representations back to a probability distribution over the tokens.

Transformer layers can be one of two types, encoder and decoder. In the original paper both of them were used, while later models included only one type of them. BERT is an example of an encoder-only model; GPT are decoder-only models.
Input

The input text is parsed into tokens by a tokenizer, most often a byte pair encoding tokenizer, and each token is converted into a vector via looking up from a word embedding table. Then, positional information of the token is added to the word embedding.
Encoder-decoder architecture

Like earlier seq2seq models, the original transformer model used an encoder-decoder architecture. The encoder consists of encoding layers that process the input tokens iteratively one layer after another, while the decoder consists of decoding layers that iteratively process the encoder's output as well as the decoder output's tokens so far.

The function of each encoder layer is to generate contextualized token representations, where each representation corresponds to a token that "mixes" information from other input tokens via self-attention mechanism. Each decoder layer contains two attention sublayers: (1) cross-attention for incorporating the output of encoder (contextualized input token representations), and (2) self-attention for "mixing" information among the input tokens to the decoder (i.e., the tokens generated so far during inference time).[37][38]

Both the encoder and decoder layers have a feed-forward neural network for additional processing of the outputs and contain residual connections and layer normalization steps.[38]
Scaled dot-product attention

The transformer building blocks are scaled dot-product attention units. For each attention unit, the transformer model learns three weight matrices: the query weights {\displaystyle W_{Q}}, the key weights {\displaystyle W_{K}}, and the value weights {\displaystyle W_{V}}. For each token {\displaystyle i}, the input token representation {\displaystyle x_{i}} is multiplied with each of the three weight matrices to produce a query vector {\displaystyle q_{i}=x_{i}W_{Q}}, a key vector {\displaystyle k_{i}=x_{i}W_{K}}, and a value vector {\displaystyle v_{i}=x_{i}W_{V}}. Attention weights are calculated using the query and key vectors: the attention weight {\displaystyle a_{ij}} from token {\displaystyle i} to token {\displaystyle j} is the dot product between {\displaystyle q_{i}} and {\displaystyle k_{j}}. The attention weights are divided by the square root of the dimension of the key vectors, {\displaystyle {\sqrt {d_{k}}}}, which stabilizes gradients during training, and passed through a softmax which normalizes the weights. The fact that {\displaystyle W_{Q}} and {\displaystyle W_{K}} are different matrices allows attention to be non-symmetric: if token {\displaystyle i} attends to token {\displaystyle j} (i.e. {\displaystyle q_{i}\cdot k_{j}} is large), this does not necessarily mean that token {\displaystyle j} will attend to token {\displaystyle i} (i.e. {\displaystyle q_{j}\cdot k_{i}} could be small). The output of the attention unit for token {\displaystyle i} is the weighted sum of the value vectors of all tokens, weighted by {\displaystyle a_{ij}}, the attention from token {\displaystyle i} to each token.

The attention calculation for all tokens can be expressed as one large matrix calculation using the softmax function, which is useful for training due to computational matrix operation optimizations that quickly compute matrix operations. The matrices {\displaystyle Q}, {\displaystyle K} and {\displaystyle V} are defined as the matrices where the {\displaystyle i}th rows are vectors {\displaystyle q_{i}}, {\displaystyle k_{i}}, and {\displaystyle v_{i}} respectively. Then we can represent the attention as

{\displaystyle {\begin{aligned}{\text{Attention}}(Q,K,V)={\text{softmax}}\left({\frac {QK^{\mathrm {T} }}{\sqrt {d_{k}}}}\right)V\end{aligned}}}

where softmax is taken over the horizontal axis.
Multi-head attention

One set of {\displaystyle \left(W_{Q},W_{K},W_{V}\right)} matrices is called an attention head, and each layer in a transformer model has multiple attention heads. While each attention head attends to the tokens that are relevant to each token, multiple attention heads allow the model to do this for different definitions of "relevance". In addition, the influence field representing relevance can become progressively dilated in successive layers. Many transformer attention heads encode relevance relations that are meaningful to humans. For example, some attention heads can attend mostly to the next word, while others mainly attend from verbs to their direct objects.[39] The computations for each attention head can be performed in parallel, which allows for fast processing. The outputs for the attention layer are concatenated to pass into the feed-forward neural network layers.

Concretely, let the multiple attention heads be indexed by {\displaystyle i}, then we have{\displaystyle {\text{MultiheadedAttention}}(Q,K,V)={\text{Concat}}_{i\in [\#heads]}({\text{Attention}}(XW_{i}^{Q},XW_{i}^{K},XW_{i}^{V}))W^{O}} where the matrix {\displaystyle X} is the concatenation of word embeddings, and the matrices {\displaystyle W_{i}^{Q},W_{i}^{K},W_{i}^{V}} are "projection matrices" owned by individual attention head {\displaystyle i}, and {\displaystyle W^{O}} is a final projection matrix owned by the whole multi-headed attention head.
Masked attention

It may be necessary to cut out attention links between some word-pairs. For example, the decoder, when decoding for the token position {\displaystyle t}, should not have access to the token at position {\displaystyle t+1}. This may be accomplished before the softmax stage by adding a mask matrix {\displaystyle M} that is {\displaystyle -\infty } at entries where the attention link must be cut, and {\displaystyle 0} at other places:{\displaystyle {\begin{aligned}{\text{MaskedAttention}}(Q,K,V)={\text{softmax}}\left(M+{\frac {QK^{\mathrm {T} }}{\sqrt {d_{k}}}}\right)V\end{aligned}}}For example, the following mask matrix is used in autoregressive modeling:{\displaystyle M={\begin{bmatrix}0&-\infty &-\infty &\dots &-\infty \\0&0&-\infty &\dots &-\infty \\0&0&0&\dots &-\infty \\\vdots &\vdots &\vdots &\ddots &\vdots \\0&0&0&\dots &0\end{bmatrix}}}In words, it means that each token can pay attention to itself, and every token before it, but not any after it.
Encoder

Each encoder consists of two major components: a self-attention mechanism and a feed-forward neural network. The self-attention mechanism accepts input encodings from the previous encoder and weights their relevance to each other to generate output encodings. The feed-forward neural network further processes each output encoding individually. These output encodings are then passed to the next encoder as its input, as well as to the decoders.

The first encoder takes positional information and embeddings of the input sequence as its input, rather than encodings. The positional information is necessary for the transformer to make use of the order of the sequence, because no other part of the transformer makes use of this.[1]

The encoder is bidirectional. Attention can be placed on tokens before and after the current token. Tokens are used instead of words to account for polysemy.

A diagram of a sinusoidal positional encoding with parameters N = 10000 , d = 100 {\displaystyle N=10000,d=100}
A diagram of a sinusoidal positional encoding with parameters {\displaystyle N=10000,d=100}
Positional encoding

A positional encoding is a fixed-size vector representation that encapsulates the relative positions of tokens within a target sequence: it provides the transformer model with information about where the words are in the input sequence.

The positional encoding is defined as a function of type {\displaystyle f:\mathbb {R} \to \mathbb {R} ^{d};d\in \mathbb {Z} ,d>0}, where {\displaystyle d} is a positive even integer. The full positional encoding – as defined in the original paper – is given by the equation:{\displaystyle (f(t)_{2k},f(t)_{2k+1})=(\sin(\theta ),\cos(\theta ))\quad \forall k\in \{0,1,\ldots ,d/2-1\}}where {\displaystyle \theta ={\frac {t}{r^{k}}},r=N^{2/d}}.

Here, {\displaystyle N} is a free parameter that should be significantly larger than the biggest {\displaystyle k} that would be input into the positional encoding function. In the original paper,[1] the authors chose {\displaystyle N=10000}.

The function is in a simpler form when written as a complex function of type {\displaystyle f:\mathbb {R} \to \mathbb {C} ^{d/2}}{\displaystyle f(t)=\left(e^{it/r^{k}}\right)_{k=0,1,\ldots ,{\frac {d}{2}}-1}}where {\displaystyle r=N^{2/d}}.

The main reason the authors chose this as the positional encoding function is that it allows one to perform shifts as linear transformations:{\displaystyle f(t+\Delta t)=\mathrm {diag} (f(\Delta t))f(t)}where {\displaystyle \Delta t\in \mathbb {R} } is the distance one wishes to shift. This allows the transformer to take any encoded position, and find the encoding of the position n-steps-ahead or n-steps-behind, by a matrix multiplication.

By taking a linear sum, any convolution can also be implemented as linear transformations:{\displaystyle \sum _{j}c_{j}f(t+\Delta t_{j})=\left(\sum _{j}c_{j}\,\mathrm {diag} (f(\Delta t_{j}))\right)f(t)}for any constants {\displaystyle c_{j}}. This allows the transformer to take any encoded position and find a linear sum of the encoded locations of its neighbors. This sum of encoded positions, when fed into the attention mechanism, would create attention weights on its neighbors, much like what happens in a convolutional neural network language model. In the author's words, "we hypothesized it would allow the model to easily learn to attend by relative position." 