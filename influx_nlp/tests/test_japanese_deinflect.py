from __future__ import annotations
from inline_snapshot import snapshot
from lib.japanese_deinflect.deinflect import Deinflector
from lib.japanese_deinflect.word_type import WordType
from lib.japanese_deinflect.derivations import rules


deinflector = Deinflector()


def get_deinflected(word_to_deconjugate):
    results = deinflector.unconjugate(word_to_deconjugate)
    assert len(results) > 0, f"No results for {word_to_deconjugate}"

    best_result = results[0]
    deconjugated_result = best_result["base"]

    derivation_path = [d for d in best_result["derivation_sequence"]["derivations"]]
    return deconjugated_result, derivation_path


def test_grammar_rules():
    assert get_deinflected('言ってもいいですよ') == snapshot(('言う', [WordType.TE_FORM, WordType.MO_AFTER_TE, WordType.II, WordType.POLITE_DESU_VERB, WordType.YO_PARTICLE]))
    assert get_deinflected('遊べそうじゃないね') == snapshot(('遊ぶ', [WordType.POTENTIAL, WordType.MASU_STEM, WordType.APPEARANCE, WordType.DA, WordType.NEGATIVE_NAI_VERB, WordType.NE_PARTICLE]))
    assert get_deinflected('誘ってもらわれてくれなかった') == snapshot(('誘う', [WordType.TE_FORM, WordType.MORAU, WordType.PASSIVE, WordType.TE_FORM, WordType.KURERU, WordType.NEGATIVE_NAI_VERB, WordType.PLAIN_PAST]))
    assert get_deinflected('遊んでるべく') == snapshot(('遊ぶ', [WordType.TE_FORM, WordType.SHORT_IRU, WordType.BEKU]))
    assert get_deinflected('敷きやがりなさい') == snapshot(('敷く', [WordType.MASU_STEM, WordType.YAGARU, WordType.MASU_STEM, WordType.NASAI]))
    assert get_deinflected('重なり次第だ') == snapshot(('重なる', [WordType.MASU_STEM, WordType.SHIDAI, WordType.DA]))
    assert get_deinflected('生き過ぎだ') == snapshot(('生きる', [WordType.MASU_STEM, WordType.SUGI, WordType.DA]))
    assert get_deinflected('覚え難いの') == snapshot(('覚える', [WordType.MASU_STEM, WordType.GATAI, WordType.EXPLANATORY_NO_PARTICLE]))
    assert get_deinflected('覚えがたいよ') == snapshot(('覚える', [WordType.MASU_STEM, WordType.GATAI, WordType.YO_PARTICLE]))
    assert get_deinflected('飛びつつあった') == snapshot(('飛ぶ', [WordType.MASU_STEM, WordType.TSUTSU_ARU, WordType.PLAIN_PAST]))
    assert get_deinflected('笑いたいのでありたい') == snapshot(('笑う', [WordType.MASU_STEM, WordType.TAI, WordType.EXPLANATORY_NO_PARTICLE, WordType.DA, WordType.DE_ARU, WordType.MASU_STEM, WordType.TAI]))
    assert get_deinflected('笑いたくなった') == snapshot(('笑う', [WordType.MASU_STEM, WordType.TAI, WordType.ADVERB, WordType.NARU, WordType.PLAIN_PAST]))
    assert get_deinflected('笑うはずです') == snapshot(('笑う', [WordType.HAZU, WordType.DA, WordType.POLITE_DESU_VERB]))
    assert get_deinflected('笑わないようだろう') == snapshot(('笑う', [WordType.NEGATIVE_NAI_VERB, WordType.YOU, WordType.DA, WordType.DAROU]))
    assert get_deinflected('笑ったようね') == snapshot(('笑う', [WordType.PLAIN_PAST, WordType.YOU, WordType.NE_PARTICLE]))
    assert get_deinflected('来たばかりです') == snapshot(('来る', [WordType.PLAIN_PAST, WordType.TA_BAKARI, WordType.DA, WordType.POLITE_DESU_VERB]))
    assert get_deinflected('死んじゃったりして') == snapshot(('死ぬ', [WordType.TE_FORM, WordType.SHIMAU, WordType.JAU, WordType.TARI, WordType.TE_FORM]))
    assert get_deinflected('死んじゃったら') == snapshot(('死ぬ', [WordType.TE_FORM, WordType.SHIMAU, WordType.JAU, WordType.TARA]))
    assert get_deinflected('叫んですみませんでした') == snapshot(('叫ぶ', [WordType.TE_FORM, WordType.SUMANAI, WordType.SUMIMASEN, WordType.POLITE_MASEN_DESHITA]))
    assert get_deinflected('沈んでもかまわない') == snapshot(('沈む', [WordType.TE_FORM, WordType.MO_AFTER_TE, WordType.KAMAU, WordType.NEGATIVE_NAI_VERB]))
    assert get_deinflected('沈んでいった') == snapshot(('沈む', [WordType.TE_FORM, WordType.TE_IKU, WordType.PLAIN_PAST]))
    assert get_deinflected('上がってくよ') == snapshot(('上がる', [WordType.TE_FORM, WordType.TE_IKU, WordType.YO_PARTICLE]))
    assert get_deinflected('話してこないだろう') == snapshot(('話す', [WordType.TE_FORM, WordType.TE_KURU, WordType.NEGATIVE_NAI_VERB, WordType.DAROU]))
    assert get_deinflected('終わらせてからでしょうね') == snapshot(('終わる', [WordType.CAUSATIVE, WordType.TE_FORM, WordType.TE_KARA, WordType.DA, WordType.DAROU, WordType.POLITE_DESHOU, WordType.NE_PARTICLE]))
    assert get_deinflected('名乗って欲しかったな') == snapshot(('名乗る', [WordType.TE_FORM, WordType.HOSHII, WordType.PLAIN_PAST, WordType.NA_PARTICLE]))
    assert get_deinflected('試してみてね') == snapshot(('試す', [WordType.TE_FORM, WordType.MIRU, WordType.TE_FORM, WordType.NE_PARTICLE]))
    assert get_deinflected('忘れちゃったね') == snapshot(('忘れる', [WordType.TE_FORM, WordType.SHIMAU, WordType.CHAU, WordType.PLAIN_PAST, WordType.NE_PARTICLE]))
    assert get_deinflected('見てあげなさい') == snapshot(('見る', [WordType.TE_FORM, WordType.AGERU, WordType.MASU_STEM, WordType.NASAI]))
    assert get_deinflected('下がってくれよ') == snapshot(('下がる', [WordType.TE_FORM, WordType.KURERU, WordType.IMPERATIVE, WordType.YO_PARTICLE]))
    assert get_deinflected('笑わなくてはいけないよ') == snapshot(('笑う', [WordType.NEGATIVE_NAI_VERB, WordType.NAKUTE_NAKEREBA_IKENAI_NARANAI, WordType.YO_PARTICLE]))
    assert get_deinflected('笑っては駄目なのよ') == snapshot(('笑う', [WordType.TE_FORM, WordType.TE_DAME, WordType.DA, WordType.EXPLANATORY_NO_PARTICLE, WordType.YO_PARTICLE]))
    assert get_deinflected('笑ってはいけないのだ') == snapshot(('笑う', [WordType.TE_FORM, WordType.TE_IKENAI_NARANAI, WordType.EXPLANATORY_NO_PARTICLE, WordType.DA]))
    assert get_deinflected('笑ってはいけないんだ') == snapshot(('笑う', [WordType.TE_FORM, WordType.TE_IKENAI_NARANAI, WordType.EXPLANATORY_NO_PARTICLE, WordType.DA]))
    assert get_deinflected('笑ってはいけないのだ') == snapshot(('笑う', [WordType.TE_FORM, WordType.TE_IKENAI_NARANAI, WordType.EXPLANATORY_NO_PARTICLE, WordType.DA]))
    assert get_deinflected('笑わなくてはいけないよ') == snapshot(('笑う', [WordType.NEGATIVE_NAI_VERB, WordType.NAKUTE_NAKEREBA_IKENAI_NARANAI, WordType.YO_PARTICLE]))
    assert get_deinflected('笑わされる') == snapshot(('笑う', [WordType.CAUSATIVE, WordType.SHORTENED_CAUSATIVE, WordType.PASSIVE]))
    assert get_deinflected('逃げてもいい') == snapshot(('逃げる', [WordType.TE_FORM, WordType.MO_AFTER_TE, WordType.II]))
    assert get_deinflected('食べなくてよいよ') == snapshot(('食べる', [WordType.NEGATIVE_NAI_VERB, WordType.TE_FORM, WordType.II, WordType.II, WordType.YO_PARTICLE]))
    assert get_deinflected('食べなくていいよ') == snapshot(('食べる', [WordType.NEGATIVE_NAI_VERB, WordType.TE_FORM, WordType.II, WordType.YO_PARTICLE]))
    assert get_deinflected('食べなくてはいいよ') == snapshot(('食べる', [WordType.NEGATIVE_NAI_VERB, WordType.TE_FORM, WordType.WA_AFTER_TE, WordType.II, WordType.YO_PARTICLE]))
    assert get_deinflected('食べに') == snapshot(('食べる', [WordType.MASU_STEM, WordType.MASU_STEM_NI]))
    assert get_deinflected('逃げなよ') == snapshot(('逃げる', [WordType.MASU_STEM, WordType.NASAI, WordType.YO_PARTICLE]))
    assert get_deinflected('逃げるなよ') == snapshot(('逃げる', [WordType.NA_COMMAND, WordType.YO_PARTICLE]))
    assert get_deinflected('逃げやすいですね') == snapshot(('逃げる', [WordType.MASU_STEM, WordType.YASUI, WordType.POLITE_DESU_VERB, WordType.NE_PARTICLE]))
    assert get_deinflected('逃げにくいですね') == snapshot(('逃げる', [WordType.MASU_STEM, WordType.NIKUI, WordType.POLITE_DESU_VERB, WordType.NE_PARTICLE]))
    assert get_deinflected('逃げられすぎた') == snapshot(('逃げる', [WordType.POTENTIAL_PASSIVE, WordType.MASU_STEM, WordType.SUGIRU, WordType.PLAIN_PAST]))
    assert get_deinflected('逃げられ過ぎた') == snapshot(('逃げる', [WordType.POTENTIAL_PASSIVE, WordType.MASU_STEM, WordType.SUGIRU, WordType.PLAIN_PAST]))
    assert get_deinflected('逃げ方ですね') == snapshot(('逃げる', [WordType.MASU_STEM, WordType.KATA, WordType.DA, WordType.POLITE_DESU_VERB, WordType.NE_PARTICLE]))
    assert get_deinflected('逃げかたですね') == snapshot(('逃げる', [WordType.MASU_STEM, WordType.KATA, WordType.DA, WordType.POLITE_DESU_VERB, WordType.NE_PARTICLE]))
    assert get_deinflected('逃げがちですね') == snapshot(('逃げる', [WordType.MASU_STEM, WordType.GACHI, WordType.DA, WordType.POLITE_DESU_VERB, WordType.NE_PARTICLE]))
    assert get_deinflected('追われながら') == snapshot(('追う', [WordType.PASSIVE, WordType.MASU_STEM, WordType.NAGARA]))
    assert get_deinflected('出しはしないよ') == snapshot(('出す', [WordType.MASU_STEM, WordType.MASU_STEM_WA_SHINAI, WordType.YO_PARTICLE]))
    assert get_deinflected('行きたがっていますね') == snapshot(('行く', [WordType.MASU_STEM, WordType.TAI, WordType.GARU, WordType.TE_FORM, WordType.IRU, WordType.MASU_STEM, WordType.POLITE_MASU, WordType.NE_PARTICLE]))
    assert get_deinflected('行くらしくないですね') == snapshot(('行く', [WordType.RASHII, WordType.NEGATIVE_NAI_VERB, WordType.POLITE_DESU_VERB, WordType.NE_PARTICLE]))
    assert get_deinflected('信じられないみたいだね') == snapshot(('信じる', [WordType.POTENTIAL_PASSIVE, WordType.NEGATIVE_NAI_VERB, WordType.MITAI, WordType.DA, WordType.NE_PARTICLE]))
    assert get_deinflected('信じられるが早いか') == snapshot(('信じる', [WordType.POTENTIAL_PASSIVE, WordType.GA_HAYAI_KA]))
    assert get_deinflected('信じられるがはやいか') == snapshot(('信じる', [WordType.POTENTIAL_PASSIVE, WordType.GA_HAYAI_KA, WordType.GA_HAYAI_KA]))
    assert get_deinflected('言われるまえだよ') == snapshot(('言う', [WordType.PASSIVE, WordType.MAE, WordType.DA, WordType.YO_PARTICLE]))
    assert get_deinflected('言われる前だよ') == snapshot(('言う', [WordType.PASSIVE, WordType.MAE, WordType.DA, WordType.YO_PARTICLE]))
    assert get_deinflected('言わないよ') == snapshot(('言う', [WordType.NEGATIVE_NAI_VERB, WordType.YO_PARTICLE]))
    assert get_deinflected('おいておいたことになったのだ') == snapshot(('おく', [WordType.TE_FORM, WordType.OKU, WordType.PLAIN_PAST, WordType.KOTO_NI_NARU, WordType.PLAIN_PAST, WordType.EXPLANATORY_NO_PARTICLE, WordType.DA]))
    assert get_deinflected('おいておくことにした') == snapshot(('おく', [WordType.TE_FORM, WordType.OKU, WordType.KOTO_NI_SURU, WordType.PLAIN_PAST]))
    assert get_deinflected('返したことなのですよ') == snapshot(('返す', [WordType.PLAIN_PAST, WordType.KOTO_NOMINALIZER, WordType.DA, WordType.EXPLANATORY_NO_PARTICLE, WordType.DA, WordType.POLITE_DESU_VERB, WordType.YO_PARTICLE]))
    assert get_deinflected('帰ったのだよ') == snapshot(('帰る', [WordType.PLAIN_PAST, WordType.EXPLANATORY_NO_PARTICLE, WordType.DA, WordType.YO_PARTICLE]))
    # assert get_deinflected('殺されるな') == snapshot(('殺す', [WordType.PASSIVE, WordType.NA_PARTICLE])) # commented out in js version for some reason (ignore for now)
    assert get_deinflected('はしゃぐことがあることがあるだろうよ') == snapshot(('はしゃぐ', [WordType.OCCASIONAL_OCCURANCE_ARU, WordType.OCCASIONAL_OCCURANCE_ARU, WordType.DAROU, WordType.YO_PARTICLE]))
    assert get_deinflected('止めることができる') == snapshot(('止める', [WordType.POTENTIAL]))
    assert get_deinflected('止めることができているよ') == snapshot(('止める', [WordType.POTENTIAL, WordType.TE_FORM, WordType.IRU, WordType.YO_PARTICLE]))
    assert get_deinflected('止められるまでだよね') == snapshot(('止める', [WordType.POTENTIAL_PASSIVE, WordType.MADE_PARTICLE, WordType.DA, WordType.YO_PARTICLE, WordType.NE_PARTICLE]))
    assert get_deinflected('停止せよ') == snapshot(('停止する', [WordType.IMPERATIVE]))
    assert get_deinflected('書ければ') == snapshot(('書く', [WordType.POTENTIAL, WordType.BA_FORM]))
    assert get_deinflected('離さなくない') == snapshot(('離す', [WordType.NEGATIVE_NAI_VERB, WordType.NEGATIVE_NAI_VERB]))
    assert get_deinflected('離さなくなさそうです') == snapshot(('離す', [WordType.NEGATIVE_NAI_VERB, WordType.NEGATIVE_NAI_VERB, WordType.APPEARANCE, WordType.DA, WordType.POLITE_DESU_VERB]))
    assert get_deinflected('離さなかろう') == snapshot(('離す', [WordType.NEGATIVE_NAI_VERB, WordType.VOLITIONAL]))
    assert get_deinflected('離さないべき') == snapshot(('離す', [WordType.NEGATIVE_NAI_VERB, WordType.BEKI]))
    assert get_deinflected('離さなかったらよければ') == snapshot(('離す', [WordType.NEGATIVE_NAI_VERB, WordType.TARA, WordType.II, WordType.II, WordType.BA_FORM]))
    assert get_deinflected('来る') == snapshot(('来る', []))
    assert get_deinflected('来ない') == snapshot(('来る', [WordType.NEGATIVE_NAI_VERB]))
    assert get_deinflected('来た') == snapshot(('来る', [WordType.PLAIN_PAST]))
    assert get_deinflected('来い') == snapshot(('来る', [WordType.IMPERATIVE]))
    assert get_deinflected('せず') == snapshot(('する', [WordType.ZU]))
    assert get_deinflected('しない') == snapshot(('する', [WordType.NEGATIVE_NAI_VERB]))
    assert get_deinflected('しなければ') == snapshot(('する', [WordType.NEGATIVE_NAI_VERB, WordType.BA_FORM]))
    assert get_deinflected('言っとけた') == snapshot(('言う', [WordType.TE_FORM, WordType.OKU, WordType.POTENTIAL, WordType.PLAIN_PAST]))
    assert get_deinflected('言って置かれた') == snapshot(('言う', [WordType.TE_FORM, WordType.OKU, WordType.OKU, WordType.PASSIVE, WordType.PLAIN_PAST]))
    assert get_deinflected('確認すべきです') == snapshot(('確認する', [WordType.BEKI, WordType.DA, WordType.POLITE_DESU_VERB]))
    assert get_deinflected('書けなさそうです') == snapshot(('書く', [WordType.POTENTIAL, WordType.NEGATIVE_NAI_VERB, WordType.APPEARANCE, WordType.DA, WordType.POLITE_DESU_VERB]))
    assert get_deinflected('離れていただけないでしょうか') == snapshot(('離れる', [WordType.TE_FORM, WordType.MORAU, WordType.POLITE_ITADAKU, WordType.POTENTIAL, WordType.NEGATIVE_NAI_VERB, WordType.DAROU, WordType.POLITE_DESHOU, WordType.KA_PARTICLE]))
    assert get_deinflected('離れてもらえないでしょうか') == snapshot(('離れる', [WordType.TE_FORM, WordType.MORAU, WordType.POTENTIAL, WordType.NEGATIVE_NAI_VERB, WordType.DAROU, WordType.POLITE_DESHOU, WordType.KA_PARTICLE]))
    assert get_deinflected('離れてもらいたいです') == snapshot(('離れる', [WordType.TE_FORM, WordType.MORAU, WordType.MASU_STEM, WordType.TAI, WordType.POLITE_DESU_VERB]))
    assert get_deinflected('励ます') == snapshot(('励ます', []))
    assert get_deinflected('話します') == snapshot(('話す', [WordType.MASU_STEM, WordType.POLITE_MASU]))
    assert get_deinflected('話すです') == snapshot(('話す', [WordType.POLITE_DESU_VERB]))
    assert get_deinflected('信じます') == snapshot(('信じる', [WordType.MASU_STEM, WordType.POLITE_MASU]))
    assert get_deinflected('信じるです') == snapshot(('信じる', [WordType.POLITE_DESU_VERB]))
    assert get_deinflected('行きません') == snapshot(('行く', [WordType.MASU_STEM, WordType.POLITE_MASEN]))
    assert get_deinflected('得ません') == snapshot(('得る', [WordType.MASU_STEM, WordType.POLITE_MASEN]))
    assert get_deinflected('語らないです') == snapshot(('語る', [WordType.NEGATIVE_NAI_VERB, WordType.POLITE_DESU_VERB]))
    assert get_deinflected('語らないです') == snapshot(('語る', [WordType.NEGATIVE_NAI_VERB, WordType.POLITE_DESU_VERB]))
    assert get_deinflected('弾けない') == snapshot(('弾く', [WordType.POTENTIAL, WordType.NEGATIVE_NAI_VERB]))
    assert get_deinflected('集まりました') == snapshot(('集まる', [WordType.MASU_STEM, WordType.POLITE_MASU, WordType.POLITE_MASHITA]))
    assert get_deinflected('信じました') == snapshot(('信じる', [WordType.MASU_STEM, WordType.POLITE_MASU, WordType.POLITE_MASHITA]))
    assert get_deinflected('笑いませんでした') == snapshot(('笑う', [WordType.MASU_STEM, WordType.POLITE_MASEN, WordType.POLITE_MASEN_DESHITA]))
    assert get_deinflected('放った') == snapshot(('放る', [WordType.PLAIN_PAST]))
    assert get_deinflected('覚えた') == snapshot(('覚える', [WordType.PLAIN_PAST]))
    assert get_deinflected('言わなかった') == snapshot(('言う', [WordType.NEGATIVE_NAI_VERB, WordType.PLAIN_PAST]))
    assert get_deinflected('照らなかった') == snapshot(('照る', [WordType.NEGATIVE_NAI_VERB, WordType.PLAIN_PAST]))
    assert get_deinflected('咲いて') == snapshot(('咲く', [WordType.TE_FORM]))
    assert get_deinflected('消えて') == snapshot(('消える', [WordType.TE_FORM]))
    assert get_deinflected('解きまして') == snapshot(('解く', [WordType.MASU_STEM, WordType.POLITE_MASU, WordType.TE_FORM]))
    assert get_deinflected('変わらなくて') == snapshot(('変わる', [WordType.NEGATIVE_NAI_VERB, WordType.TE_FORM]))
    assert get_deinflected('打てば') == snapshot(('打つ', [WordType.BA_FORM]))
    assert get_deinflected('打たなければ') == snapshot(('打つ', [WordType.NEGATIVE_NAI_VERB, WordType.BA_FORM]))
    assert get_deinflected('置かれる') == snapshot(('置く', [WordType.PASSIVE]))
    assert get_deinflected('置かれることがあるよ') == snapshot(('置く', [WordType.PASSIVE, WordType.OCCASIONAL_OCCURANCE_ARU, WordType.YO_PARTICLE]))
    assert get_deinflected('得られる') == snapshot(('得る', [WordType.POTENTIAL_PASSIVE]))
    assert get_deinflected('帰れる') == snapshot(('帰る', [WordType.POTENTIAL]))
    assert get_deinflected('帰れなくて') == snapshot(('帰る', [WordType.POTENTIAL, WordType.NEGATIVE_NAI_VERB, WordType.TE_FORM]))
    assert get_deinflected('帰れなければ') == snapshot(('帰る', [WordType.POTENTIAL, WordType.NEGATIVE_NAI_VERB, WordType.BA_FORM]))
    assert get_deinflected('帰れました') == snapshot(('帰る', [WordType.POTENTIAL, WordType.MASU_STEM, WordType.POLITE_MASU, WordType.POLITE_MASHITA]))
    assert get_deinflected('放たれました') == snapshot(('放つ', [WordType.PASSIVE, WordType.MASU_STEM, WordType.POLITE_MASU, WordType.POLITE_MASHITA]))
    assert get_deinflected('黙れ') == snapshot(('黙る', [WordType.IMPERATIVE]))
    # assert get_deinflected('いろ') == snapshot(('いる', [WordType.IMPERATIVE])) # commented out in js version for some reason (ignore for now)
    assert get_deinflected('食べよう') == snapshot(('食べる', [WordType.VOLITIONAL]))
    assert get_deinflected('殺されましょう') == snapshot(('殺す', [WordType.PASSIVE, WordType.MASU_STEM, WordType.POLITE_MASU, WordType.POLITE_MASHOU]))
    assert get_deinflected('降りそう') == snapshot(('降りる', [WordType.MASU_STEM, WordType.APPEARANCE]))
    assert get_deinflected('走れそう') == snapshot(('走る', [WordType.POTENTIAL, WordType.MASU_STEM, WordType.APPEARANCE]))
    assert get_deinflected('殴られそう') == snapshot(('殴る', [WordType.POTENTIAL_PASSIVE, WordType.MASU_STEM, WordType.APPEARANCE]))
    assert get_deinflected('買えそう') == snapshot(('買う', [WordType.POTENTIAL, WordType.MASU_STEM, WordType.APPEARANCE]))
    assert get_deinflected('書かれそう') == snapshot(('書く', [WordType.PASSIVE, WordType.MASU_STEM, WordType.APPEARANCE]))
    assert get_deinflected('走るそう') == snapshot(('走る', [WordType.HEARSAY]))
    assert get_deinflected('得られるそう') == snapshot(('得る', [WordType.POTENTIAL_PASSIVE, WordType.HEARSAY]))
    assert get_deinflected('押されるそう') == snapshot(('押す', [WordType.PASSIVE, WordType.HEARSAY]))
    assert get_deinflected('食べれるそう') == snapshot(('食べる', [WordType.POTENTIAL, WordType.HEARSAY]))
    assert get_deinflected('行かないそう') == snapshot(('行く', [WordType.NEGATIVE_NAI_VERB, WordType.HEARSAY]))
    assert get_deinflected('行かなかったそう') == snapshot(('行く', [WordType.NEGATIVE_NAI_VERB, WordType.PLAIN_PAST, WordType.HEARSAY]))
    assert get_deinflected('歌わせる') == snapshot(('歌う', [WordType.CAUSATIVE]))
    assert get_deinflected('歌わせた') == snapshot(('歌う', [WordType.CAUSATIVE, WordType.PLAIN_PAST]))
    assert get_deinflected('歌わす') == snapshot(('歌う', [WordType.CAUSATIVE, WordType.SHORTENED_CAUSATIVE]))
    assert get_deinflected('歌わせられた') == snapshot(('歌う', [WordType.CAUSATIVE, WordType.POTENTIAL_PASSIVE, WordType.PLAIN_PAST]))
    assert get_deinflected('歌わせない') == snapshot(('歌う', [WordType.CAUSATIVE, WordType.NEGATIVE_NAI_VERB]))
    assert get_deinflected('歌わせたら') == snapshot(('歌う', [WordType.CAUSATIVE, WordType.TARA]))
    assert get_deinflected('歌わせられたら') == snapshot(('歌う', [WordType.CAUSATIVE, WordType.POTENTIAL_PASSIVE, WordType.TARA]))
    assert get_deinflected('歌わせなかったら') == snapshot(('歌う', [WordType.CAUSATIVE, WordType.NEGATIVE_NAI_VERB, WordType.TARA]))
    assert get_deinflected('放たれましたら') == snapshot(('放つ', [WordType.PASSIVE, WordType.MASU_STEM, WordType.POLITE_MASU, WordType.TARA]))
    assert get_deinflected('帰れたら') == snapshot(('帰る', [WordType.POTENTIAL, WordType.TARA]))
    assert get_deinflected('置かれたら') == snapshot(('置く', [WordType.PASSIVE, WordType.TARA]))
    assert get_deinflected('歌わせられなきゃ') == snapshot(('歌う', [WordType.CAUSATIVE, WordType.POTENTIAL_PASSIVE, WordType.NEGATIVE_NAI_VERB, WordType.NAKYA]))
    assert get_deinflected('歌わせなきゃ') == snapshot(('歌う', [WordType.CAUSATIVE, WordType.NEGATIVE_NAI_VERB, WordType.NAKYA]))
    assert get_deinflected('放たれなきゃ') == snapshot(('放つ', [WordType.PASSIVE, WordType.NEGATIVE_NAI_VERB, WordType.NAKYA]))
    assert get_deinflected('放たれなくちゃ') == snapshot(('放つ', [WordType.PASSIVE, WordType.NEGATIVE_NAI_VERB, WordType.NAKUCHA]))
    assert get_deinflected('歌わせられた挙句') == snapshot(('歌う', [WordType.CAUSATIVE, WordType.POTENTIAL_PASSIVE, WordType.PLAIN_PAST, WordType.AGEKU]))
    assert get_deinflected('歌いたい') == snapshot(('歌う', [WordType.MASU_STEM, WordType.TAI]))
    assert get_deinflected('歌いたくない') == snapshot(('歌う', [WordType.MASU_STEM, WordType.TAI, WordType.NEGATIVE_NAI_VERB]))
    assert get_deinflected('歌いたくはない') == snapshot(('歌う', [WordType.MASU_STEM, WordType.TAI, WordType.NEGATIVE_NAI_VERB]))
    assert get_deinflected('歌わせられたい') == snapshot(('歌う', [WordType.CAUSATIVE, WordType.POTENTIAL_PASSIVE, WordType.MASU_STEM, WordType.TAI]))
    assert get_deinflected('歌わせたい') == snapshot(('歌う', [WordType.CAUSATIVE, WordType.MASU_STEM, WordType.TAI]))
    assert get_deinflected('歌わせないで') == snapshot(('歌う', [WordType.CAUSATIVE, WordType.NEGATIVE_NAI_VERB, WordType.NAIDE]))
    assert get_deinflected('食べさせられたかった') == snapshot(('食べる', [WordType.CAUSATIVE, WordType.POTENTIAL_PASSIVE, WordType.MASU_STEM, WordType.TAI, WordType.PLAIN_PAST]))
    assert get_deinflected('行くな') == snapshot(('行く', [WordType.NA_COMMAND]))
    assert get_deinflected('信じるな') == snapshot(('信じる', [WordType.NA_COMMAND]))
    assert get_deinflected('行くまい') == snapshot(('行く', [WordType.NEGATIVE_VOLITIONAL]))
    assert get_deinflected('信じるまい') == snapshot(('信じる', [WordType.NEGATIVE_VOLITIONAL]))
    assert get_deinflected('話している') == snapshot(('話す', [WordType.TE_FORM, WordType.IRU]))
    assert get_deinflected('話してある') == snapshot(('話す', [WordType.TE_FORM, WordType.ARU]))
    assert get_deinflected('話しておる') == snapshot(('話す', [WordType.TE_FORM, WordType.ORU]))
    assert get_deinflected('話していさせて') == snapshot(('話す', [WordType.TE_FORM, WordType.IRU, WordType.CAUSATIVE, WordType.TE_FORM]))
    assert get_deinflected('離されて') == snapshot(('離す', [WordType.PASSIVE, WordType.TE_FORM]))
    assert get_deinflected('離せて') == snapshot(('離す', [WordType.POTENTIAL, WordType.TE_FORM]))
    assert get_deinflected('得られて') == snapshot(('得る', [WordType.POTENTIAL_PASSIVE, WordType.TE_FORM]))
    assert get_deinflected('撫でさせられていさせて') == snapshot(('撫でる', [WordType.CAUSATIVE, WordType.POTENTIAL_PASSIVE, WordType.TE_FORM, WordType.IRU, WordType.CAUSATIVE, WordType.TE_FORM]))
    assert get_deinflected('書かれてあった') == snapshot(('書く', [WordType.PASSIVE, WordType.TE_FORM, WordType.ARU, WordType.PLAIN_PAST]))
    # assert get_deinflected('書かれてなかった') == snapshot(('書く', [WordType.PASSIVE, WordType.TE_FORM, WordType.ARU, WordType.NEGATIVE_NAI_VERB, WordType.PLAIN_PAST])) # commented out in js version for some reason (ignore for now)
    assert get_deinflected('撫でさせられていさせなさい') == snapshot(('撫でる', [WordType.CAUSATIVE, WordType.POTENTIAL_PASSIVE, WordType.TE_FORM, WordType.IRU, WordType.CAUSATIVE, WordType.MASU_STEM, WordType.NASAI]))
    assert get_deinflected('撫でさせられていさせな') == snapshot(('撫でる', [WordType.CAUSATIVE, WordType.POTENTIAL_PASSIVE, WordType.TE_FORM, WordType.IRU, WordType.CAUSATIVE, WordType.MASU_STEM, WordType.NASAI]))
    assert get_deinflected('撫でさせられてはいさせな') == snapshot(('撫でる', [WordType.CAUSATIVE, WordType.POTENTIAL_PASSIVE, WordType.TE_FORM, WordType.WA_AFTER_TE, WordType.IRU, WordType.CAUSATIVE, WordType.MASU_STEM, WordType.NASAI]))
    assert get_deinflected('書かず') == snapshot(('書く', [WordType.ZU]))
    assert get_deinflected('書けず') == snapshot(('書く', [WordType.POTENTIAL, WordType.ZU]))
    assert get_deinflected('書かれず') == snapshot(('書く', [WordType.PASSIVE, WordType.ZU]))
    assert get_deinflected('撫でさせられていさせず') == snapshot(('撫でる', [WordType.CAUSATIVE, WordType.POTENTIAL_PASSIVE, WordType.TE_FORM, WordType.IRU, WordType.CAUSATIVE, WordType.ZU]))
    assert get_deinflected('撫でさせられず') == snapshot(('撫でる', [WordType.CAUSATIVE, WordType.POTENTIAL_PASSIVE, WordType.ZU]))
    assert get_deinflected('撫でさせられたく') == snapshot(('撫でる', [WordType.CAUSATIVE, WordType.POTENTIAL_PASSIVE, WordType.MASU_STEM, WordType.TAI, WordType.ADVERB]))
    assert get_deinflected('撫でさせられたくなく') == snapshot(('撫でる', [WordType.CAUSATIVE, WordType.POTENTIAL_PASSIVE, WordType.MASU_STEM, WordType.TAI, WordType.NEGATIVE_NAI_VERB, WordType.ADVERB]))
    assert get_deinflected('撫でさせられたくはなく') == snapshot(('撫でる', [WordType.CAUSATIVE, WordType.POTENTIAL_PASSIVE, WordType.MASU_STEM, WordType.TAI, WordType.NEGATIVE_NAI_VERB, WordType.ADVERB]))
    assert get_deinflected('座ってはいる') == snapshot(('座る', [WordType.TE_FORM, WordType.WA_AFTER_TE, WordType.IRU]))
    assert get_deinflected('されたくない') == snapshot(('する', [WordType.PASSIVE, WordType.MASU_STEM, WordType.TAI, WordType.NEGATIVE_NAI_VERB]))
    assert get_deinflected('書きません') == snapshot(('書く', [WordType.MASU_STEM, WordType.POLITE_MASEN]))
    assert get_deinflected('しませんでした') == snapshot(('する', [WordType.MASU_STEM, WordType.POLITE_MASEN, WordType.POLITE_MASEN_DESHITA]))
    assert get_deinflected('為さいませんでした') == snapshot(('為さる', [WordType.MASU_STEM, WordType.POLITE_MASEN, WordType.POLITE_MASEN_DESHITA]))
    assert get_deinflected('書いてください') == snapshot(('書く', [WordType.TE_FORM, WordType.KUDASAI]))
    assert get_deinflected('撫でさせられぬ') == snapshot(('撫でる', [WordType.CAUSATIVE, WordType.POTENTIAL_PASSIVE, WordType.NEGATIVE_NAI_VERB, WordType.NU]))
    assert get_deinflected('撫でさせられぬよ') == snapshot(('撫でる', [WordType.CAUSATIVE, WordType.POTENTIAL_PASSIVE, WordType.NEGATIVE_NAI_VERB, WordType.NU, WordType.YO_PARTICLE]))
    assert get_deinflected('撫でさせられぬよね') == snapshot(('撫でる', [WordType.CAUSATIVE, WordType.POTENTIAL_PASSIVE, WordType.NEGATIVE_NAI_VERB, WordType.NU, WordType.YO_PARTICLE, WordType.NE_PARTICLE]))
    assert get_deinflected('仰いませんでした') == snapshot(('仰る', [WordType.MASU_STEM, WordType.POLITE_MASEN, WordType.POLITE_MASEN_DESHITA]))
    assert get_deinflected('話してあるだろう') == snapshot(('話す', [WordType.TE_FORM, WordType.ARU, WordType.DAROU]))
    assert get_deinflected('話してあるでしょう') == snapshot(('話す', [WordType.TE_FORM, WordType.ARU, WordType.DAROU, WordType.POLITE_DESHOU]))
    assert get_deinflected('行った方が良くないよ') == snapshot(('行う', [WordType.PLAIN_PAST, WordType.HOU_GA_II, WordType.NEGATIVE_NAI_VERB, WordType.YO_PARTICLE]))


def test_fuzzy_derivation():
    results = deinflector.unconjugate('仰いませんでしたじゃやらぱが', fuzzy=True)
    assert len(results) > 0
    assert len(results) == snapshot(2)


def analyze_word(word: str) -> str:
    results = deinflector.unconjugate(word)

    if not results:
        return f"No results found for '{word}'"

    output = []
    output.append(f"Analysis of '{word}':")
    output.append(f"Dictionary form: {results[0]['base']}")
    output.append("")

    derivations = results[0]["derivation_sequence"]["derivations"]
    word_progression = results[0]["derivation_sequence"]["word_form_progression"]

    if not derivations:
        output.append("This is already in dictionary form.")
        return "\n".join(output)

    output.append("Derivation steps:")
    current_word = results[0]["base"]

    for i, (derivation_type, next_word) in enumerate(zip(derivations, word_progression)):

        output.append(f"{i+1}. {current_word} → {next_word}")
        output.append(f"   Form: {derivation_type.value}")

        current_word = next_word
        output.append("")

    return "\n".join(output)


# Test that all derivation rules have valid word types
def test_word_type_validation():
    for rule in rules:
        assert rule.get('unconjugated_word_type') is not None, f'No unconjugated word type for {rule.get("unconjugated_ending")} -> {rule.get("conjugated_ending")}'
        assert rule.get('conjugated_word_type') is not None, f'No conjugated word type for {rule.get("unconjugated_ending")} -> {rule.get("conjugated_ending")}'
        assert rule.get('conjugated_ending') is not None, f'No conjugated ending for {rule.get("unconjugated_ending")} -> {rule.get("conjugated_ending")}'
        assert rule.get('unconjugated_ending') is not None, f'No unconjugated ending for {rule.get("unconjugated_ending")} -> {rule.get("conjugated_ending")}'


# Test that maximum recursion depth is respected
def test_maximum_recursion_depth():
    # Test with a complex conjugated form that would normally require deep recursion
    results_with_limit = deinflector.unconjugate('撫でさせられぬよね', recursion_depth_limit=3)
    results_without_limit = deinflector.unconjugate('撫でさせられぬよね', recursion_depth_limit=10)

    # With a low recursion limit, we should get fewer or no results
    # With a higher limit, we should get more results
    assert len(results_with_limit) <= len(results_without_limit)


def test_ambiguous_deinflections():
    """Test cases with ambiguous deinflections that return multiple possibilities."""

    results_itte = deinflector.unconjugate('いって')
    assert len(results_itte) == snapshot(13)
    assert results_itte == snapshot(
        [
            {'base': 'いう', 'derivation_sequence': {'derivations': [WordType.TE_FORM], 'word_form_progression': ['いって']}},
            {'base': 'いつ', 'derivation_sequence': {'derivations': [WordType.TE_FORM], 'word_form_progression': ['いって']}},
            {'base': 'いる', 'derivation_sequence': {'derivations': [WordType.TE_FORM], 'word_form_progression': ['いって']}},
            {'base': 'いう', 'derivation_sequence': {'derivations': [WordType.TE_FORM], 'word_form_progression': ['いって']}},
            {'base': 'いつ', 'derivation_sequence': {'derivations': [WordType.TE_FORM], 'word_form_progression': ['いって']}},
            {'base': 'いる', 'derivation_sequence': {'derivations': [WordType.TE_FORM], 'word_form_progression': ['いって']}},
            {'base': 'いって', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'いっる', 'derivation_sequence': {'derivations': [WordType.TE_FORM], 'word_form_progression': ['いって']}},
            {'base': 'いっつ', 'derivation_sequence': {'derivations': [WordType.IMPERATIVE], 'word_form_progression': ['いって']}},
            {'base': 'いっつ', 'derivation_sequence': {'derivations': [WordType.IMPERATIVE], 'word_form_progression': ['いって']}},
            {'base': 'いっる', 'derivation_sequence': {'derivations': [WordType.TE_FORM], 'word_form_progression': ['いって']}},
            {'base': 'いっつ', 'derivation_sequence': {'derivations': [WordType.POTENTIAL, WordType.MASU_STEM], 'word_form_progression': ['いってる', 'いって']}},
            {'base': 'いってる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['いって']}},
        ]
    )

    results_shita = deinflector.unconjugate('した')
    assert len(results_shita) == snapshot(8)
    assert results_shita == snapshot(
        [
            {'base': 'する', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['した']}},
            {'base': 'する', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['した']}},
            {'base': 'す', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['した']}},
            {'base': 'す', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['した']}},
            {'base': 'した', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'しる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['した']}},
            {'base': 'しる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['した']}},
            {'base': 'したる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['した']}},
        ]
    )

    results_aru = deinflector.unconjugate('ある')
    assert len(results_aru) == snapshot(4)
    assert results_aru == snapshot(
        [
            {'base': 'ある', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'ある', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'ある', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'あるる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['ある']}},
        ]
    )

    results_iru = deinflector.unconjugate('いる')
    assert len(results_iru) == snapshot(4)
    assert results_iru == snapshot(
        [
            {'base': 'いる', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'いる', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'いる', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'いるる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['いる']}},
        ]
    )

    results_kita = deinflector.unconjugate('きた')
    assert len(results_kita) == snapshot(4)
    assert results_kita == snapshot(
        [
            {'base': 'きた', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'きる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['きた']}},
            {'base': 'きる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['きた']}},
            {'base': 'きたる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['きた']}},
        ]
    )

    results_katta = deinflector.unconjugate('かった')
    assert len(results_katta) == snapshot(10)
    assert results_katta == snapshot(
        [
            {'base': 'かう', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['かった']}},
            {'base': 'かつ', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['かった']}},
            {'base': 'かる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['かった']}},
            {'base': 'かう', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['かった']}},
            {'base': 'かつ', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['かった']}},
            {'base': 'かる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['かった']}},
            {'base': 'かった', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'かっる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['かった']}},
            {'base': 'かっる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['かった']}},
            {'base': 'かったる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['かった']}},
        ]
    )

    results_totta = deinflector.unconjugate('取った')
    assert len(results_totta) == snapshot(10)
    assert results_totta == snapshot(
        [
            {'base': '取る', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['取った']}},
            {'base': '取る', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['取った']}},
            {'base': '取う', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['取った']}},
            {'base': '取つ', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['取った']}},
            {'base': '取う', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['取った']}},
            {'base': '取つ', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['取った']}},
            {'base': '取った', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': '取っる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['取った']}},
            {'base': '取っる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['取った']}},
            {'base': '取ったる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['取った']}},
        ]
    )


def test_analysis():
    """Test that grammar explanations are generated correctly for example words."""
    example_words = [
        "行きます",
        "食べられない",
        "読んでいた",
        "書かれる",
        "飲みたい",
    ]

    output_parts = []
    for word in example_words:
        analysis = analyze_word(word)
        output_parts.append(analysis)
        output_parts.append("-" * 50)
        output_parts.append("")

    if output_parts:
        output_parts = output_parts[:-2]

    combined_output = "\n".join(output_parts)
    assert combined_output == snapshot(
        """\
Analysis of '行きます':
Dictionary form: 行く

Derivation steps:
1. 行く → 行き
   Form: ます Stem

2. 行き → 行きます
   Form: ます Polite

--------------------------------------------------

Analysis of '食べられない':
Dictionary form: 食べる

Derivation steps:
1. 食べる → 食べられる
   Form: Potential Or Passive Form

2. 食べられる → 食べられない
   Form: ない Negative

--------------------------------------------------

Analysis of '読んでいた':
Dictionary form: 読む

Derivation steps:
1. 読む → 読んで
   Form: て・で Form

2. 読んで → 読んでいる
   Form: ている・でいる Continuing State/Result

3. 読んでいる → 読んでいた
   Form: Plain Past

--------------------------------------------------

Analysis of '書かれる':
Dictionary form: 書く

Derivation steps:
1. 書く → 書かれる
   Form: Passive Form

--------------------------------------------------

Analysis of '飲みたい':
Dictionary form: 飲む

Derivation steps:
1. 飲む → 飲み
   Form: ます Stem

2. 飲み → 飲みたい
   Form: たい Want To Do
"""
    )
