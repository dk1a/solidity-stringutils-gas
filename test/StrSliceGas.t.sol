// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { StrSlice, StrSlice__, toSlice, StrCharsIter } from "@dk1a/solidity-stringutils/src/StrSlice.sol";

import { memeq, memcmp } from "@dk1a/solidity-stringutils/src/utils/mem.sol";
import { memchr } from "@dk1a/solidity-stringutils/src/utils/memchr.sol";

import { console } from "forge-std/src/console.sol";

import { strings } from "solidity-stringutils/src/strings.sol";

using { toSlice } for string;

contract StrSliceGasTest {
    // 32, 33 bytes
    string constant LOREM_IPSUM_32 = "Lorem ipsum dolor sit amet, cons";
    string constant LOREM_IPSUM_32_LAST_4 = "cons";
    string constant LOREM_IPSUM_33 = "Lorem ipsum dolor sit amet, conse";
    string constant LOREM_IPSUM_33_LAST_4 = "onse";
    // 100 bytes
    string constant LOREM_IPSUM =
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore.";
    string constant LOREM_IPSUM_PAT_20_AT_70 =
    "d tempor incididunt ";

    // 1000 chars, 3000 bytes
    string constant LOREM_IPSUM_CHINESE =
    unicode"間催一能影著視有長防去検真航。階命猶献歩死競沢報宇去大重権児幕社。読祭育情湯校切洋通盗問撃合稿億柔本社語進。主監打再伝描換聞化習郎月掛字意営付視同電。振選求毎能域難安謙税海将次。校探者児告崎梨時了視親合政金種大真感待公。禁金英入界質了景箱三俊助資。措商課乗条求腰奈足方開制購龍暮浜和日訴正。気公僚恐塞属皇去結真央査彦。台略無学卒要糖京改分一編主中無。援際谷初宣会町役著欧週問取敗理。守図横発人境主向段教権時閣大氏父意寺収実。代画解公上決慮調伎差気権認歩意東応予講。真掲聞周国監毎求週香毎新川債折会聴看更要。秘造渡夏稿共峡王運活平芸馬挙導。毎中卓図落朝勤忙座約芸質機載銭無藤東。供館愛前北著謝知捕漏史一量。死験目昇内平護合記町文芸情真署。詐家性国滋注旅可集廃者量首。持必帯天了引金指水経裁正響作。報江学兵集関約母夕樹科広超冬点演務。背司地月現減身権週集元写。課豆獲無駆天汚崎指図黒命職球謙燃理示同。入面消機知限写型明題乗景。国図図森尊盛批減処乱帳選溝院芸護手経喜社。井読購就相必情積内重試除。農性刊覇載午持歌徹白政士載庵優詰闘進。損件就態近提天退分細移治。文無積更約再作液半支医他著知堀予況。充上需棋後災容言撤隣首院掲続出料相中分。主急加転委員湿口真新係情授便海和。気金特時請確次賞済校北来測美春貴拉試。以総健的氏止済月絡基室社初必匹美当。通症政楽予条白進載訪地暮登中担意芸。行協品乃陥析夜質程急録沼周記大作。写経座進謎人川馬以昨手獲作鍋債日級版勢。任提肉通方社投間稼決占督一議。話舗機総評田内禁食谷間面無天正哲稿。外示対販続責金戒本自画和姫。問能投単道文覧話並性庭市増球国大傷員立。内方著通的名写薦捕供需美。切却性越暮不校任勝聡公行貢政載万判不費端。設流結報障康一前歌京欧岡裁。彼話馬絶情禁狙接県用識日大。敬就写金圧被簡枕況岸能無決環現軍丘。真談知課問図値意一検疑性。優致禁派登択挑転物応漫真属気戻尊録。岩楽催死調谷性成乃祉最止赤。第文写題人外進注載社府効演作注。肉治向材設土泊手誤欲性応住語書官繕作。学藤術備慣連逃猛決南発面拠六。政斉転実更写訪上装年載投更銀利。金決濯攻写紀多暮情紳長表森出国目宣毎介総。井愛後善験芸首面相鏡京自野続果。式問題替価点違芸少争掲紙。作付腕陸載著事本語演体移移。大雇提誕倉辺戸内味億金優問。地来部第済大通字呂総運段何夫韓。締後文財意健兵年雑阜公突。内始祝入画東現炭視半捕";

    string constant LOREM_IPSUM_CHINESE_PAT_200_AT_700 =
    unicode"捕供需美。切却性越暮不校任勝聡公行貢政載万判不費端。設流結報障康一前歌京欧岡裁。彼話馬絶情禁狙接県用識日大。敬就写金圧被簡枕況岸能無決環現軍丘。真談知課問図値意一検疑性。優致禁派登択挑転物応漫真属気戻尊録。岩楽催死調谷性成乃祉最止赤。第文写題人外進注載社府効演作注。肉治向材設土泊手誤欲性応住語書官繕作。学藤術備慣連逃猛決南発面拠六。政斉転実更写訪上装年載投更銀利。金決濯攻写紀多暮情紳長表森出国目宣";

    /*//////////////////////////////////////////////////////////////////////////
                                    MEMCMP, MEMEQ
    //////////////////////////////////////////////////////////////////////////*/

    function _logGas_memeq_memcmp(StrSlice s1, StrSlice s2) internal view returns (bool a, int256 b) {
        uint256 gas;
        uint256 len = s1.len() < s2.len() ? s1.len() : s2.len();
        uint256 ptr1 = s1.ptr();
        uint256 ptr2 = s2.ptr();

        // memeq
        gas = gasleft();
        a = memeq(ptr1, ptr2, len);
        gas -= gasleft();
        console.log("memeq:  %s gas (%s len)", gas, len);
        uint256 memeqGas = gas;

        // memcmp
        gas = gasleft();
        b = memcmp(ptr1, ptr2, len);
        gas -= gasleft();
        console.log("memcmp: %s gas (%s len, %s/10 diff)", gas, len, (gas * 10) / memeqGas);
    }

    function testGasMemcmp() public view {
        _logGas_memeq_memcmp(toSlice("A"), toSlice("A"));
        _logGas_memeq_memcmp(toSlice("1234567"), toSlice("1234567"));
        _logGas_memeq_memcmp(
            toSlice("Lorem ipsum dolor sit amet, cons"),
            toSlice("Lorem ipsum dolor sit amet, cons")
        );
        _logGas_memeq_memcmp(
            toSlice("Lorem ipsum dolor sit amet, conse"),
            toSlice("Lorem ipsum dolor sit amet, conse")
        );
        _logGas_memeq_memcmp(toSlice(LOREM_IPSUM), toSlice(LOREM_IPSUM));
        _logGas_memeq_memcmp(toSlice(LOREM_IPSUM_CHINESE), toSlice(LOREM_IPSUM_CHINESE));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        MEMCHR
    //////////////////////////////////////////////////////////////////////////*/

    function _logGas_memchr(StrSlice s, uint8 x) internal view returns (uint256 a) {
        uint256 gas;
        uint256 len = s.len();
        uint256 ptr = s.ptr();

        gas = gasleft();
        a = memchr(ptr, len, x);
        gas -= gasleft();
        if (a == type(uint256).max) {
            console.log("memchr: %s gas, %s len, NOT FOUND", gas, len);
        } else {
            console.log("memchr: %s gas, %s len, %s index", gas, len, a);
        }
    }

    function testGasMemchr() public view {
        _logGas_memchr(toSlice("A"), 0);
        _logGas_memchr(
            toSlice("Lorem ipsum dolor sit amet, cons"),
            0
        );
        _logGas_memchr(
            toSlice("Lorem ipsum dolor sit amet, conse"),
            0
        );
        _logGas_memchr(toSlice(LOREM_IPSUM), 0);
        _logGas_memchr(toSlice(LOREM_IPSUM_CHINESE), 0);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        FIND
    //////////////////////////////////////////////////////////////////////////*/

    function _logGas_find(StrSlice s1, StrSlice s2) internal view returns (uint256 iL, uint256 iR, strings.slice memory b) {
        uint256 gasL;
        uint256 gasR;

        gasL = gasleft();
        iL = s1.find(s2);
        gasL -= gasleft();
        gasR = gasleft();
        iR = s1.rfind(s2);
        gasR -= gasleft();
        if (iL == type(uint256).max) {
            console.log("(not found)");
        } else {
            console.log("indexes: (%s, %s)", iL, iR);
        }
        console.log("find:  %s gas, %s len, %s pat", gasL, s1.len(), s2.len());
        console.log("rfind: %s gas, %s len, %s pat", gasR, s1.len(), s2.len());

        strings.slice memory a_s1 = strings.toSlice(s1.toString());
        strings.slice memory a_s2 = strings.toSlice(s2.toString());

        gasL = gasleft();
        b = strings.find(a_s1, a_s2);
        gasL -= gasleft();

        a_s1 = strings.toSlice(s1.toString());
        a_s2 = strings.toSlice(s2.toString());

        gasR = gasleft();
        b = strings.rfind(a_s1, a_s2);
        gasR -= gasleft();
        console.log("find:  %s gas (Arachnid/solidity-stringutils)", gasL);
        console.log("rfind: %s gas (Arachnid/solidity-stringutils)", gasR);
        console.log("--");
    }

    function testGasFind() public view {
        _logGas_find(toSlice("A"), toSlice("A"));
        _logGas_find(
            toSlice("Lorem ipsum dolor sit amet, cons"),
            toSlice("cons")
        );
        _logGas_find(
            toSlice("Lorem ipsum dolor sit amet, conse"),
            toSlice("conse")
        );
        _logGas_find(toSlice(LOREM_IPSUM), toSlice(LOREM_IPSUM_PAT_20_AT_70));
        _logGas_find(toSlice(LOREM_IPSUM_CHINESE), toSlice(LOREM_IPSUM_CHINESE_PAT_200_AT_700));
        _logGas_find(toSlice(LOREM_IPSUM), toSlice("Lorem ipsum"));
        _logGas_find(toSlice(LOREM_IPSUM), toSlice(LOREM_IPSUM));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        ADD
    //////////////////////////////////////////////////////////////////////////*/

    function _logGas_add(StrSlice s1, StrSlice s2) internal view returns (string memory a) {
        uint256 gas;

        gas = gasleft();
        a = s1.add(s2);
        gas -= gasleft();
        console.log("add:    %s gas, %s len1, %s len2", gas, s1.len(), s2.len());

        strings.slice memory a_s1 = strings.toSlice(s1.toString());
        strings.slice memory a_s2 = strings.toSlice(s2.toString());
        gas = gasleft();
        a = strings.concat(a_s1, a_s2);
        gas -= gasleft();
        console.log("concat: %s gas (Arachnid/solidity-stringutils)", gas);
    }

    function testGasAdd() public view {
        _logGas_add(toSlice("A"), toSlice("A"));
        _logGas_add(toSlice(LOREM_IPSUM_32), toSlice(LOREM_IPSUM_32));
        _logGas_add(toSlice(LOREM_IPSUM_33), toSlice(LOREM_IPSUM_33));
        _logGas_add(toSlice(LOREM_IPSUM), toSlice(LOREM_IPSUM));
        _logGas_add(toSlice(LOREM_IPSUM_CHINESE), toSlice(LOREM_IPSUM_CHINESE));

        _logGas_add(toSlice(LOREM_IPSUM), toSlice("A"));
        _logGas_add(toSlice(LOREM_IPSUM_CHINESE), toSlice("A"));
        _logGas_add(toSlice(LOREM_IPSUM), toSlice(LOREM_IPSUM_32));
        _logGas_add(toSlice(LOREM_IPSUM), toSlice(LOREM_IPSUM_33));
        _logGas_add(toSlice(LOREM_IPSUM_CHINESE), toSlice(LOREM_IPSUM));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        JOIN
    //////////////////////////////////////////////////////////////////////////*/

    function _logGas_join(StrSlice sep, StrSlice s1, StrSlice s2, StrSlice s3) internal view returns (string memory a) {
        uint256 gas;

        StrSlice[] memory slices = new StrSlice[](3);
        slices[0] = s1;
        slices[1] = s2;
        slices[2] = s3;

        gas = gasleft();
        a = sep.join(slices);
        gas -= gasleft();
        console.log("join: %s gas, %s sep, %s total array bytes", gas, sep.len(), s1.len() + s2.len() + s3.len());

        // at high lengths the latter allocator costs a bit more, ~2% at 10000-20000 bytes
        strings.slice memory a_sep = strings.toSlice(sep.toString());
        strings.slice[] memory a_slices = new strings.slice[](3);
        a_slices[0] = strings.toSlice(s1.toString());
        a_slices[1] = strings.toSlice(s1.toString());
        a_slices[2] = strings.toSlice(s1.toString());
        gas = gasleft();
        a = strings.join(a_sep, a_slices);
        gas -= gasleft();
        console.log("join: %s gas (Arachnid/solidity-stringutils)", gas);
    }

    function testGasJoin() public view {
        _logGas_join(toSlice("A"), toSlice("A"), toSlice("A"), toSlice("A"));
        _logGas_join(toSlice(LOREM_IPSUM_32), toSlice("A"), toSlice("A"), toSlice("A"));
        _logGas_join(toSlice("A"), toSlice("A"), toSlice(LOREM_IPSUM_32), toSlice(LOREM_IPSUM_33));
        _logGas_join(toSlice(LOREM_IPSUM_32), toSlice(LOREM_IPSUM), toSlice(LOREM_IPSUM), toSlice("A"));
        _logGas_join(toSlice(LOREM_IPSUM_33), toSlice(LOREM_IPSUM), toSlice(LOREM_IPSUM), toSlice("A"));
        _logGas_join(toSlice(LOREM_IPSUM_32), toSlice(LOREM_IPSUM_CHINESE), toSlice(LOREM_IPSUM_CHINESE), toSlice(LOREM_IPSUM_CHINESE));
        _logGas_join(toSlice(LOREM_IPSUM_CHINESE), toSlice(LOREM_IPSUM_CHINESE), toSlice(LOREM_IPSUM_CHINESE), toSlice(LOREM_IPSUM_CHINESE));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        CMP
    //////////////////////////////////////////////////////////////////////////*/

    function _logGas_cmp(StrSlice s1, StrSlice s2) internal view returns (int256 a) {
        uint256 gas;

        gas = gasleft();
        a = s1.cmp(s2);
        gas -= gasleft();
        console.log("cmp: %s gas, %s len1, %s len2", gas, s1.len(), s2.len());

        strings.slice memory a_s1 = strings.toSlice(s1.toString());
        strings.slice memory a_s2 = strings.toSlice(s2.toString());
        gas = gasleft();
        a = strings.compare(a_s1, a_s2);
        gas -= gasleft();
        console.log("cmp: %s gas (Arachnid/solidity-stringutils)", gas);
    }

    function testGasCmp() public view {
        console.log("-- equality --");
        _logGas_cmp(toSlice("A"), toSlice("A"));
        _logGas_cmp(toSlice(LOREM_IPSUM_32), toSlice(LOREM_IPSUM_32));
        _logGas_cmp(toSlice(LOREM_IPSUM_33), toSlice(LOREM_IPSUM_33));
        _logGas_cmp(toSlice(LOREM_IPSUM), toSlice(LOREM_IPSUM));
        _logGas_cmp(toSlice(LOREM_IPSUM_CHINESE), toSlice(LOREM_IPSUM_CHINESE));

        string memory s2;
        console.log("-- inequality --");
        _logGas_cmp(toSlice(LOREM_IPSUM), toSlice("A"));
        s2 = LOREM_IPSUM_33;
        bytes(s2)[bytes(s2).length - 1] = "!";
        _logGas_cmp(toSlice(LOREM_IPSUM_33), toSlice(s2));
        s2 = LOREM_IPSUM;
        bytes(s2)[bytes(s2).length - 1] = "!";
        _logGas_cmp(toSlice(LOREM_IPSUM), toSlice(s2));
        string memory s1 = string(abi.encodePacked(LOREM_IPSUM_CHINESE, "."));
        s2 = string(abi.encodePacked(LOREM_IPSUM_CHINESE, "!"));
        _logGas_cmp(toSlice(s1), toSlice(s2));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        SPLIT
    //////////////////////////////////////////////////////////////////////////*/

    function _logGas_split(StrSlice s, StrSlice pat)
        internal
        view
        returns (StrSlice l, StrSlice r, strings.slice memory a_l)
    {
        uint256 gas;

        gas = gasleft();
        (,l,r) = s.splitOnce(pat);
        gas -= gasleft();
        console.log("[%s:%s] len, %s pat", l.len(), r.len(), pat.len());
        console.log("splitOnce:  %s gas", gas);
        gas = gasleft();
        (,l,r) = s.rsplitOnce(pat);
        gas -= gasleft();
        console.log("[%s:%s]", l.len(), r.len());
        console.log("rsplitOnce: %s gas", gas);

        strings.slice memory a_s = strings.toSlice(s.toString());
        strings.slice memory a_pat = strings.toSlice(pat.toString());

        gas = gasleft();
        a_l = strings.split(a_s, a_pat);
        gas -= gasleft();
        console.log("split:      %s gas", gas);

        a_s = strings.toSlice(s.toString());
        a_pat = strings.toSlice(pat.toString());

        gas = gasleft();
        a_l = strings.rsplit(a_s, a_pat);
        gas -= gasleft();
        console.log("rsplit:     %s gas", gas);
        console.log("--");
    }

    function testGasSplit() public view {
        _logGas_split(toSlice("A"), toSlice("A"));
        _logGas_split(toSlice("A"), toSlice("AB"));
        _logGas_split(toSlice(LOREM_IPSUM_32), toSlice(LOREM_IPSUM_32));
        _logGas_split(toSlice(LOREM_IPSUM_32), toSlice("dolor"));
        _logGas_split(toSlice(LOREM_IPSUM_32), toSlice(LOREM_IPSUM_32_LAST_4));
        _logGas_split(toSlice(LOREM_IPSUM_33), toSlice(LOREM_IPSUM_33));
        _logGas_split(toSlice(LOREM_IPSUM_33), toSlice("dolor"));
        _logGas_split(toSlice(LOREM_IPSUM_33), toSlice(LOREM_IPSUM_33_LAST_4));
        _logGas_split(toSlice(LOREM_IPSUM), toSlice(","));
        _logGas_split(toSlice(LOREM_IPSUM), toSlice(LOREM_IPSUM_PAT_20_AT_70));
        _logGas_split(toSlice(LOREM_IPSUM), toSlice(unicode"。"));
        _logGas_split(toSlice(LOREM_IPSUM_CHINESE), toSlice(LOREM_IPSUM_CHINESE));
        _logGas_split(toSlice(LOREM_IPSUM_CHINESE), toSlice(unicode"。"));
        _logGas_split(toSlice(LOREM_IPSUM_CHINESE), toSlice(LOREM_IPSUM_CHINESE_PAT_200_AT_700));
        _logGas_split(toSlice(LOREM_IPSUM_CHINESE), toSlice("not found pattern"));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CHARS COUNT
    //////////////////////////////////////////////////////////////////////////*/

    function _logGas_charsCount(StrSlice s) internal view returns (uint256 a, bool b) {
        uint256 gas;

        gas = gasleft();
        a = s.chars().count();
        gas -= gasleft();
        console.log("chars-count:  %s gas, %s len", gas, s.len());

        gas = gasleft();
        b = s.chars().validateUtf8();
        gas -= gasleft();
        console.log("validate:     %s gas, %s len", gas, s.len());

        gas = gasleft();
        a = s.chars().unsafeCount();
        gas -= gasleft();
        console.log("unsafe-count: %s gas, %s len", gas, s.len());

        strings.slice memory a_s = strings.toSlice(s.toString());
        gas = gasleft();
        a = strings.len(a_s);
        gas -= gasleft();
        console.log("len:          %s gas (Arachnid/solidity-stringutils)", gas);
        console.log("--");
    }

    function testGasCharsCount() public view {
        _logGas_charsCount(toSlice("A"));
        _logGas_charsCount(toSlice(LOREM_IPSUM_32));
        _logGas_charsCount(toSlice(LOREM_IPSUM_33));
        _logGas_charsCount(toSlice(LOREM_IPSUM));
        _logGas_charsCount(toSlice(LOREM_IPSUM_CHINESE));
    }
}