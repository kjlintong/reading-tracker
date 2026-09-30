#!/usr/bin/env python3
"""生成合成示例书库：app/assets/seed/library.json

为什么用合成数据而不是真实书库：
仓库是公开的，随包发布的种子数据等于公开给所有克隆者看。真实书库里的
阅读偏好（读什么、读多久、读了什么网文）、私人书签页码、微信读书内部 ID 与
deepLink 都指向一个具体的人，不适合开源。所以这里换成 38 本合成记录——
书目元数据（书名/作者/分类/简介）来自公开出版物信息，但阅读行为字段
（状态、进度、评分、起止日期、时长）全部重新编造。

结构刻意与真实产物保持一致：books / notes / stats / shelfMeta 四段，
让 SeedImporter、统计页、报告页、截图测试走的是同一条代码路径，
只是数据不再是某个人的私人记录。

重新生成：python3 tools/gen-sample-library.py
幂等：确定性随机种子，重跑产出字节级一致。
"""

import datetime
import json
import os
import random

random.seed(20260930)

OUT = os.path.join(os.path.dirname(__file__), "..", "app", "assets", "seed", "library.json")
PREFIX = "sample-book-"

# 36 本公开出版物：分类均衡分布，避免统计图表退化成一根柱子。
# (title, authors, publisher, publishedAt, categoryPath, description)
BOOKS = [
    ("百年孤独", ["加西亚·马尔克斯"], "南海出版公司", "2011-06", "文学-外国文学",
     "魔幻现实主义的奠基之作，布恩迪亚家族七代人的兴衰史。"),
    ("红楼梦", ["曹雪芹"], "人民文学出版社", "1982-10", "文学-古典文学",
     "以贾府兴衰写尽封建大家族的人物百态，中国古典小说的顶峰。"),
    ("活着", ["余华"], "作家出版社", "2012-08", "文学-当代文学",
     "福贵的一生，苦难之中对生存本身的坚持。"),
    ("围城", ["钱锺书"], "人民文学出版社", "2015-09", "文学-当代文学",
     "婚姻如围城，城外的人想进去，城里的人想出来。"),
    ("人类简史", ["尤瓦尔·赫拉利"], "中信出版社", "2014-11", "社科-人类学",
     "从认知革命、农业革命到科学革命，重写智人十万年历程。"),
    ("自私的基因", ["理查德·道金斯"], "中信出版社", "2012-09", "科普-生命科学",
     "自然选择的基本单位是基因而非个体，演化视角由此反转。"),
    ("枪炮、病菌与钢铁", ["贾雷德·戴蒙德"], "中信出版社", "2012-07", "社科-历史",
     "用地理与生态解释文明兴衰，回答人类命运为何如此不同。"),
    ("万历十五年", ["黄仁宇"], "生活·读书·新知三联书店", "1997-09", "历史-明史",
     "大历史观代表作，从十五个年份的细部切进明代政治结构。"),
    ("史记", ["司马迁"], "中华书局", "1959-01", "历史-古典史书",
     "二十四史之首，纪传体通史的开山之作。"),
    ("正义论", ["约翰·罗尔斯"], "中国社会科学出版社", "1988-06", "哲学-政治哲学",
     "作为公平的正义：无知之幕之后人们会共同选择什么原则。"),
    ("沉思录", ["马可·奥勒留"], "上海人民出版社", "2017-06", "哲学-斯多葛",
     "罗马皇帝的私人笔记，斯多葛哲学的生活实践范本。"),
    ("论自由", ["约翰·斯图尔特·密尔"], "商务印书馆", "2011-01", "哲学-政治哲学",
     "以伤害原则界定个人自由与群体强制的边界。"),
    ("原则", ["瑞·达利欧"], "中信出版社", "2018-01", "管理-方法论",
     "极度求真与极度透明，把决策抽象成可重复的原则。"),
    ("非暴力沟通", ["马歇尔·卢森堡"], "华夏出版社", "2009-01", "心理-沟通",
     "观察、感受、需要、请求四步，把指责变成可执行的对话。"),
    ("被讨厌的勇气", ["岸见一郎", "古贺史健"], "机械工业出版社", "2017-01", "心理-阿德勒",
     "以对话体重述阿德勒个体心理学，课题分离是核心概念。"),
    ("思考，快与慢", ["丹尼尔·卡尼曼"], "中信出版社", "2012-02", "心理-认知",
     "系统一与系统二，人类判断与选择中的系统性偏差。"),
    ("穷查理宝典", ["查理·芒格"], "中信出版社", "2016-09", "管理-投资",
     "多元思维模型：用多个学科的模型交叉验证同一个决策。"),
    ("经济学原理", ["曼昆"], "北京大学出版社", "2009-01", "经济-微观经济",
     "十大原理入门，供给、需求、效率与公平的取舍。"),
    ("置身事内", ["兰小欢"], "上海人民出版社", "2021-07", "经济-中国经济",
     "从地方政府行为切入，理解中国经济运作的内在逻辑。"),
    ("明朝那些事儿", ["当年明月"], "中国文史出版社", "2009-01", "历史-明史",
     "以白话叙事重写明朝三百年，历史普及读物的代表。"),
    ("三体", ["刘慈欣"], "重庆出版社", "2008-01", "科技-科幻小说",
     "黑暗森林法则与三体问题交织，硬科幻的里程碑。"),
    ("时间简史", ["史蒂芬·霍金"], "湖南科学技术出版社", "2014-09", "科普-物理",
     "从大爆炸到黑洞，写给非专业读者的宇宙简史。"),
    ("代码大全", ["史蒂夫·麦康奈尔"], "机械工业出版社", "2006-03", "计算机-软件工程",
     "结构化程序设计与构造完整程序的经验指南。"),
    ("算法导论", ["Thomas H. Cormen"], "机械工业出版社", "2012-01", "计算机-算法",
     "算法设计与分析的系统教材，动态规划、图论、数据结构齐备。"),
    ("设计模式", ["Erich Gamma"], "机械工业出版社", "2007-03", "计算机-软件工程",
     "二十三种常用设计模式，解决面向对象设计中的重复问题。"),
    ("写给大家看的设计书", ["Robin Williams"], "人民邮电出版社", "2013-04", "艺术-设计",
     "亲密性、对比、重复、对齐：平面设计四原则。"),
    ("时间的朋友", ["罗振宇"], "中信出版社", "2016-03", "成长-时间管理",
     "长期主义视角下的复利思维与个人成长。"),
    ("刻意练习", ["安德斯·艾利克森"], "机械工业出版社", "2016-04", "成长-学习方法",
     "有目的的练习与反馈回路，是专家与普通人的分野。"),
    ("学会提问", ["尼尔·布朗"], "机械工业出版社", "2014-05", "教育-批判性思维",
     "提出与评估论点的方法，区分可辩护的问题与无法回答的问题。"),
    ("教育的目的", ["罗素"], "上海译文出版社", "2013-05", "教育-教育哲学",
     "教育应培养对世界的好奇与独立判断，而非单纯的服从。"),
    ("人类群星闪耀时", ["斯蒂芬·茨威格"], "东方出版中心", "2015-01", "传记-人物",
     "十二个决定性的历史瞬间，传记文学的经典合集。"),
    ("苏东坡传", ["林语堂"], "湖南文艺出版社", "2016-11", "传记-中国",
     "以苏轼一生写宋人的精神风貌与生活态度。"),
    ("中国哲学简史", ["冯友兰"], "北京大学出版社", "2013-01", "教育-哲学",
     "从诸子百家到宋明理学，勾勒中国哲学的内在脉络。"),
    ("动物农场", ["乔治·奥威尔"], "上海译文出版社", "2011-01", "文学-寓言",
     "农场里的动物革命与它的反讽结局。"),
    ("1984", ["乔治·奥威尔"], "南海出版公司", "2014-09", "文学-反乌托邦",
     "老大哥在看着你，极权社会下的个体生存。"),
    ("西西弗神话", ["加缪"], "译林出版社", "2010-06", "哲学-存在主义",
     "荒诞命题的反转：应当想象西西弗是幸福的。"),
    ("社会的选择", ["詹姆斯·布坎南"], "经济日报出版社", "2003-01", "经济-公共选择",
     "公共选择理论：用经济学方法分析政治决策的激励结构。"),
    ("艺术的故事", ["贡布里希"], "广西美术出版社", "2007-04", "艺术-美术史",
     "从史前洞穴画到当代艺术，一部可读的艺术通史。"),
]

# 16 条合成笔记：按书名+作者关联，bookTitle 必须命中上面某本书。
NOTES = [
    ("沉思录", "马可·奥勒留", "highlight", None, "未加思索的行动不是行动，而是习惯。"),
    ("沉思录", "马可·奥勒留", "highlight", 41, "你有力量支配自己的内心，外部事件你无能为力。"),
    ("正义论", "约翰·罗尔斯", "thought", None, "无知之幕是最干净的思想实验，也是最能暴露直觉的设计。"),
    ("正义论", "约翰·罗尔斯", "highlight", 32, "没有人应因为社会的偶然因素而受益或受损。"),
    ("穷查理宝典", "查理·芒格", "highlight", 78, "反过来想，总是反过来想。"),
    ("三体", "刘慈欣", "thought", None, "给岁月以文明，而不是给文明以岁月。"),
    ("三体", "刘慈欣", "highlight", 214, "弱小和无知不是生存的障碍，傲慢才是。"),
    ("置身事内", "兰小欢", "highlight", None, "理解地方政府的行为逻辑，是理解中国经济的前提。"),
    ("刻意练习", "安德斯·艾利克森", "highlight", 23, "没有反馈的重复练习不会带来进步，只会让错误固化。"),
    ("算法导论", "Thomas H. Cormen", "thought", None, "动态规划的难点不在写法，而在正确描述子问题的状态。"),
    ("人类简史", "尤瓦尔·赫拉利", "highlight", 96, "想象的共同神话，是人类协作的真正基础设施。"),
    ("1984", "乔治·奥威尔", "review", None, "重读之后才理解，这本书危险的地方在于它太像说明书。"),
    ("西西弗神话", "加缪", "highlight", 38, "应当想象西西弗是幸福的。"),
    ("非暴力沟通", "马歇尔·卢森堡", "thought", None, "先描述事实再谈感受，指责的冲动就有了落点。"),
    ("刻意练习", "安德斯·艾利克森", "highlight", 105, "舒适区之外的练习才产生进步，这一点在多数领域都被低估。"),
    ("代码大全", "史蒂夫·麦康奈尔", "review", None, "三十年后重读仍然成立，说明结构化的工程经验不靠框架续命。"),
]

CATS = ["文学", "社科", "历史", "哲学", "心理", "经济", "管理", "科普",
        "科技", "计算机", "艺术", "成长", "教育", "传记"]
assert len(BOOKS) == 38, len(BOOKS)


def month_map(months_back):
    base = datetime.date(2026, 1, 1)
    m = base.month - months_back
    y = base.year
    while m <= 0:
        m += 12
        y -= 1
    return f"{y}-{m:02d}"


def build():
    random.seed(20260930)
    books = []
    # 状态配比接近真实书架的形态：想读多、已读次之、在读最少
    statuses = (["wish"] * 20 + ["finished"] * 11 + ["reading"] * 5 + ["paused"] * 2)
    random.shuffle(statuses)

    for i, (title, authors, publisher, pub, cat_path, desc) in enumerate(BOOKS):
        status = statuses[i]
        cat_primary = cat_path.split("-")[0]
        # 只有纸质书有 ISBN（电子书来源没有 ISBN 字段，符合真实数据形态）
        started = finished = None
        progress = 0
        rating = 0

        if status == "finished":
            started = month_map(random.randint(4, 20))
            finished = month_map(random.randint(0, 3))
            progress = 100
            rating = random.choice([3, 4, 4, 5, 3, 4])
        elif status == "reading":
            started = month_map(random.randint(0, 8))
            progress = random.choice([8, 22, 35, 47, 61, 74])
        elif status == "paused":
            started = month_map(random.randint(1, 14))
            progress = random.choice([12, 28, 33])

        is_notion = i % 3 == 0  # 三来源交替，模拟多源导入的混合结果
        src = "notion" if is_notion else ("weread" if i % 3 == 1 else "manual")
        is_paper = is_notion or src == "manual"
        isbn13 = '9787' + str(i * 7919 + 1047).zfill(9) if is_paper else None

        extra = {}
        if src == "notion":
            extra = {"notionStatus": {"wish": "Want to Read", "finished": "Finished",
                                      "reading": "Reading", "paused": "Ready to Start"}[status]}
            if random.random() < 0.5:
                extra["notionAddedAt"] = month_map(random.randint(2, 24)) + "-15"
        elif src == "weread":
            extra = {
                "wereadReadUpdateTime": "2026-08-31",
                "wereadSecret": False,
                "wereadReadingTimeSec": 0,
            }

        books.append({
            "id": f"{PREFIX}{i:03d}",
            "title": title,
            "subtitle": None,
            "authors": authors,
            "translators": [],
            "publisher": publisher,
            "publishedAt": pub,
            "isbn13": isbn13,
            "coverUrl": None,
            "coverLocalPath": None,
            "categoryPrimary": cat_primary,
            "categoryRaw": cat_path,
            "categoryPath": cat_path,
            "tags": [cat_primary],
            "description": desc,
            "language": "zh",
            "pageCount": None,
            "wordCount": None,
            "format": "paper" if is_notion else "ebook",
            "source": src,
            "sourceBookId": None,
            "sourceUrl": None,
            "status": status,
            "progressPercent": progress,
            "currentPage": None,
            "rating": rating,
            "review": None,
            "summary": None,
            "highlights": None,
            "startedAt": started,
            "finishedAt": finished,
            "borrowedFrom": None,
            "dueAt": None,
            "rereadCount": random.choice([0, 0, 0, 1]),
            "extra": extra,
            "createdAt": "2026-09-30T00:00:00.000Z",
            "updatedAt": "2026-09-30T00:00:00.000Z",
        })

    # 分类均衡校验（生成器自检，保证统计页不会画出退化图表）
    dist = {}
    for b in books:
        dist[b["categoryPrimary"]] = dist.get(b["categoryPrimary"], 0) + 1
    assert len(dist) >= 12, f"分类过少：{dist}"
    assert min(dist.values()) >= 1

    notes = []
    for i, (title, author, typ, page, content) in enumerate(NOTES):
        notes.append({
            "id": f"sample-note-{i:03d}",
            "type": typ,
            "content": content,
            "chapter": None,
            "pageAt": page,
            "source": "notion",
            "bookTitle": title,
            "bookAuthor": author,
            "createdAt": "2026-09-30T00:00:00.000Z",
        })

    # 年度统计：逐月时长 + 总时长，形态与微信读书年度统计一致（秒为单位）。
    # 键是「该月 1 号的 UTC epoch 秒」，由 datetime 推导，避免手写错月份。
    # 覆盖全年 12 个月——只填一部分会让统计页的月度时长图出现空档，
    # 看起来像数据缺了而不是真的没读。
    monthly_sec = [3900, 8800, 5200, 12400, 9600, 15200, 6400, 7800, 5200, 4100,
                   3100, 2100]
    monthly = {
        str(int(datetime.datetime(
            2026, m, 1, tzinfo=datetime.timezone.utc).timestamp())): sec
        for m, sec in zip(range(1, 13), monthly_sec)
    }
    total = sum(monthly.values())
    read_days = 68  # 全年有阅读记录的天数，约等于隔天读一次
    finished_count = sum(1 for x in books if x["status"] == "finished")

    # overall 是「注册至今累计」口径，必须不小于当年度值
    overall_read_days, overall_total_sec = 214, 447000
    assert len(monthly_sec) == 12
    assert 0 < read_days < 365
    assert overall_read_days >= read_days
    assert overall_total_sec >= total

    return {
        "books": books,
        "notes": notes,
        "stats": {
            "year": 2026,
            "annual": {
                "readTimes": monthly,
                "readDays": read_days,
                "dayAverageReadTime": round(total / read_days),
                "totalReadTime": total,
                "readRecordsWord": "书籍分布",
            },
            "overall": {
                "readTimes": monthly,
                "readDays": overall_read_days,
                "totalReadTime": overall_total_sec,
                "readStat": [
                    {"stat": "读过", "counts": f"{len(books)}本"},
                    {"stat": "读完", "counts": f"{finished_count}本"},
                    {"stat": "阅读", "counts": f"{overall_read_days}天"},
                    {"stat": "笔记", "counts": f"{len(notes)}条"},
                ],
            },
        },
        "shelfMeta": {"total": len(books),
                      "ebookCount": sum(1 for x in books if x["format"] == "ebook"),
                      "albumCount": 0, "hasMp": False, "collections": []},
    }


if __name__ == "__main__":
    data = build()
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"已生成 {len(data['books'])} 本书 / {len(data['notes'])} 条笔记 → {OUT}")
