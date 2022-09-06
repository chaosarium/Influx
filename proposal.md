# Towards an Integrated Content-Based Language Learning Environment: An Exploratory Proposal

This is adapted from my 18th July 2022 blog post under the same title. 

## The Motivation

Followed by [\@HugoFara](https://github.com/HugoFara/lwt/discussions/36)'s announcement to discontinue LWT development, I think it's time for me to think about LWT per se as well as the future for content-based language learning apps.

I am a big fan of LWT, particularly for its approach to language learning. A year ago, I released my enhanced version of LWT in the blog post [[2021-08-10 Concerning My Unofficial Version of LWT]]. I was thinking about renovating this project into something I would truly love to use as a language learner. There are several occasions in which, despite how I use LWT myself on daily basis, recommending it to others often ended up complicating things as getting LWT running and using it wasn't the most straightforward thing. Obviously, it has been a year and the project never took off—the codebase was rather difficult to understand, it was in written in PHP, it uses outdated tags in HTML 4, and time wasn't on my side either. 

Interestingly, [\@HugoFara forked my fork](https://github.com/HugoFara/lwt) half a year ago and took on the project. It was quite exciting to see that people do care about LWT, and I soon shared some of the [ideas I had for future development](https://github.com/HugoFara/lwt/discussions/14), hoping to get this project going again.

Half a year later, there was some progress on cleaning up LWT. But indeed, as concluded in [#36](https://github.com/HugoFara/lwt/discussions/36), LWT is not going anywhere. 

It was sad news for those who rely on LWT for language learning, but not necessarily bad news. Sometimes software development takes a complete rewriting, and that is okay. Perhaps quick iteration enabled by a cleaner code base would inspire a new app that shall replace LWT while maintaining its spirit.

The next question, then, is where to start. As a self-taught programmer (at least so far), I am a little concerned about missing something at the start and ending up with some massive technical debt...

Maybe I'd better start—rather than doing nothing.

This post, therefore, serves as a way for me to consolidate my vision for a next-generation content-based language learning tool and think about how one might go about developing one. 

## The Big picture

Language learning is never a straight line, so neither should my language learning app restrict how users use it. Platforms like Duolingo might have some structure to help beginners learn the basics, but they become stringent when one becomes an independent language learner. As my language journey progresses, I would almost always want to bring my own content, whether it's a pile of text or a youtube playlist.

Therefore, my vision for the next generation LWT is something like an IDE[^1]. Besides, a good language learning app shouldn't be something that teaches you a language, but a tool that you make use of to help yourself learn a language. As one of my favourite language learning quotes goes:

> Languages cannot be taught, they can only be learned  
> —Luca Lampariello

[^1]: Integrated Development Environment used by those people who write code; they often put different tools together to enable a streamlined workflow.

Calling it an IDE sounds ridiculous, but the concept is quite clear. It should be a versatile and flexible tool for doing all sorts of language learning activities, and the user should have control over how they use the tool and what content they feed into the tool. For now, I shall call this tool an Integrated Language Learning Environment (ILLE).

## A Survey of What's Already in the Wild

There are many language learning tools I have looked at. Under the ILLE framework, however, it seems that they only do part of what I would like to see. A brief summary of what I've looked at:

- **[LWT](https://hugofara.github.io/lwt/index.html)** - Needless to say, this is the one I always end up coming back to. Its feature set makes it a very powerful language learning tool; it's just a bit outdated and buggy.
- **[LingQ](https://www.lingq.com/en/)** - A commercial one. As far as I can tell, this is actually quite promising. It has its own content library but also allows you to bring your own. I didn't pay for the premium version (quite expensive), and the 20 words limit in the free version simply doesn't get me anywhere.
- **[LingL](https://github.com/gustavklopp/LingL)** - An open source alternative of LingQ and LWT written in python. It's not outdated like LWT, but its lack of some features still pushes me back to LWT.
- **[FLTR](https://sourceforge.net/projects/foreign-language-text-reader/)** - Created by the same person who built LWT. It's written in Java and feels cleaner overall, but lacks many features in LWT.
- ****[Memento](https://github.com/ripose-jp/Memento)**** - A FOSS video-based learning tool for Japanese. It comes with AnkiConnect support. At this point, it seems only targeted at Japanese learners.
- **[voracious](https://github.com/rsimmons/voracious)** - Another FOSS video-based learning tool. It supports multiple languages but seems to have not been updated since 2019.
- **[lingo-player](https://github.com/oaprograms/lingo-player)** - Another open source video player. It supports multiple languages and comes with a spaced repetition system. The last commit, however, was 7 years ago.

There are definitely things we can draw from all these projects. The current landscape seems to be that text and video content are divided. It would be tricky to use the same SRS to review words from text and video. Work is wasted, the system is not efficient, and the learning environment isn't integrated.

## The Feature Set

The environment should be "integrated". It means that the tool should be versatile, flexible, and customisable. Users should be able to bring in diverse learning materials and be able to customise the workspace to fit their needs.

For now, I think these are all features worth having.

- Workspace control
	- Panels
	- Modern looking interface
	- Themes
- Language support
	- Japanese parser (something like MeCab)
	- Google translate
	- ...
- Content support
	- A document-oriented approach to content management
		- Custom document status rather than archive/active as in LWT
	- Video player (with both subtitle and text support)
	- Plain text reader
	- Special support for lyrics?
	- Markdown reader
	- Import/Export
- Look up feature
	- Web dictionary
	- Expression lookup
	- Custom dictionaries (like mdx?)
	- TTS
	- Offline support?
	- Triggering another dictionary app by URI?
- Spaced repetition system
- Statistics
	- Graphs
	- Summaries
- Extensions?

## The Tech Stack

I don't know what to use to build this yet, but I would prefer to go with familiar technologies.

There is one crucial decision to make — whether it should be a packaged app or a web app. A packaged app saves the trouble of setting up and browser compatibilities, but a web app saves the trouble of packaging and working on multiple devices.

Regardless, a draft for now:

- Electron(?)
- JavaScript (on Bun?)
- SQLite?
- React + Next?

Alternative using Python instead

- Python
- Django
- SQLite
- React

## Oh yes one more thing

Coming up with a name for this project...
turns out to be the hardest thing ( ´▽｀)

- LingI?
- LWT#?
- LWT++?
- Lernenmittext?
- Corpustastic?
- Influx? - yeah let's go with that