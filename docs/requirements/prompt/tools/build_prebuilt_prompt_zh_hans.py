#!/usr/bin/env python3
"""
生成 prebuilt-prompt-zh-hans.json

用法:
  python tools/build_prebuilt_prompt_zh_hans.py          # 生成并覆盖
  python tools/build_prebuilt_prompt_zh_hans.py --check   # 只比较，不写文件
"""

import json
import sys
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.dirname(SCRIPT_DIR)

NEW_PROMPTS_FILE = os.path.join(ROOT_DIR, "chat_real_user_queries_zh_mixed.json")
OLD_PROMPTS_FILE = os.path.join(ROOT_DIR, "suggestions.json")
OUTPUT_FILE = os.path.join(ROOT_DIR, "prebuilt-prompt-zh-hans.json")

# ── 固定分类定义（顺序不可变）────────────────────────────────
CATEGORIES_ORDER = [
    ("life",          "日常生活"),
    ("career",        "职场学业"),
    ("family",        "家庭亲子"),
    ("creation",      "创作"),
    ("role_play",     "角色扮演"),
    ("encyclopedia",  "百科"),
    ("code",          "代码"),
    ("mathematics",   "数学"),
]

# ── 旧分类 -> 新分类映射 ─────────────────────────────────────
OLD_CATEGORY_MAP = {
    "常识":   "life",
    "创作":   "creation",
    "角色扮演": "role_play",
    "百科":   "encyclopedia",
    "代码":   "code",
    "数学":   "mathematics",
}

# ── 新 prompt 一级分类 override（按 0-based 索引）────────────
# 默认值为 "general"（后续会被二级规则进一步分配到 life/career/family）
NEW_CATEGORY_OVERRIDES = {
    # role_play
    4:   "role_play",
    6:   "role_play",
    7:   "role_play",
    8:   "role_play",
    116: "role_play",
    119: "role_play",
    124: "role_play",
    141: "role_play",
    152: "role_play",
    157: "role_play",
    164: "role_play",
    173: "role_play",
    182: "role_play",
    185: "role_play",
    # creation
    60:  "creation",
    67:  "creation",
    74:  "creation",
    79:  "creation",
    81:  "creation",
    112: "creation",
    118: "creation",
    123: "creation",
    125: "creation",
    126: "creation",
    127: "creation",
    136: "creation",
    137: "creation",
    149: "creation",
    150: "creation",
    153: "creation",
    154: "creation",
    155: "creation",
    162: "creation",
    163: "creation",
    184: "creation",
    191: "creation",
    194: "creation",
    213: "creation",
    215: "creation",
    216: "creation",
    217: "creation",
    218: "creation",
    219: "creation",
    220: "creation",
    221: "creation",
    222: "creation",
    223: "creation",
    224: "creation",
    # encyclopedia
    113: "encyclopedia",
    134: "encyclopedia",
    158: "encyclopedia",
    # code
    59:  "code",
    71:  "code",
    114: "code",
    129: "code",
    139: "code",
    156: "code",
    183: "code",
    186: "code",
}

# ── general 条目的二级分类（career / family / 默认 life）───────
# 凡是 NEW_CATEGORY_OVERRIDES 未覆盖、且此表未覆盖的，归 life
GENERAL_SUBCATEGORY_OVERRIDES = {
    # career（职场学业）
    2:   "career",
    5:   "career",
    14:  "career",
    15:  "career",
    18:  "career",
    19:  "career",
    20:  "career",
    21:  "career",
    22:  "career",
    27:  "career",
    28:  "career",
    29:  "career",
    30:  "career",
    33:  "career",
    34:  "career",
    36:  "career",
    43:  "career",
    44:  "career",
    45:  "career",
    46:  "career",
    47:  "career",
    48:  "career",
    50:  "career",
    56:  "career",
    57:  "career",
    58:  "career",
    61:  "career",
    62:  "career",
    65:  "career",
    66:  "career",
    69:  "career",
    70:  "career",
    76:  "career",
    77:  "career",
    78:  "career",
    80:  "career",
    87:  "career",
    89:  "career",
    90:  "career",
    91:  "career",
    92:  "career",
    94:  "career",
    97:  "career",
    99:  "career",
    103: "career",
    104: "career",
    109: "career",
    110: "career",
    115: "career",
    117: "career",
    128: "career",
    138: "career",
    140: "career",
    160: "career",
    165: "career",
    166: "career",
    174: "career",
    175: "career",
    176: "career",
    187: "career",
    188: "career",
    189: "career",
    192: "career",
    196: "career",
    202: "career",
    203: "career",
    206: "career",
    210: "career",
    # family（家庭亲子）
    3:   "family",
    9:   "family",
    10:  "family",
    11:  "family",
    12:  "family",
    13:  "family",
    16:  "family",
    17:  "family",
    23:  "family",
    24:  "family",
    35:  "family",
    40:  "family",
    41:  "family",
    42:  "family",
    52:  "family",
    55:  "family",
    63:  "family",
    72:  "family",
    73:  "family",
    82:  "family",
    95:  "family",
    96:  "family",
    101: "family",
    102: "family",
    105: "family",
    130: "family",
    131: "family",
    133: "family",
    135: "family",
    142: "family",
    143: "family",
    144: "family",
    145: "family",
    167: "family",
    168: "family",
    169: "family",
    172: "family",
    177: "family",
    178: "family",
    180: "family",
    181: "family",
    197: "family",
    198: "family",
    201: "family",
    204: "family",
    207: "family",
    208: "family",
    212: "family",
}


def get_new_category(idx):
    cat = NEW_CATEGORY_OVERRIDES.get(idx, "general")
    if cat == "general":
        cat = GENERAL_SUBCATEGORY_OVERRIDES.get(idx, "life")
    return cat


# ── 新 prompt rendering_name 映射（按 0-based 索引）────────
NEW_RENDERING_NAMES = {
    0: "努力了很久却感觉看不到回报，怎么调整心态？",
    1: "查出脂肪肝和尿酸高，经常应酬出差的人怎么调整？",
    2: "怎么在传统企业内部推行 AI 的4周试点方案？",
    3: "带3岁孩子出去，怎么安排半天不太崩溃的活动？",
    4: "如果王熙凤来做数字化转型，她会从哪里下手？",
    5: "遇到职业裁员，中年人的简历该怎么改才有价值？",
    6: "如果宋江是互联网大厂 CTO，他会怎么写 OKR？",
    7: "如果李白活在今天，他会怎么吐槽年轻人的痛苦？",
    8: "如果秦始皇有了微信，他会怎么吐槽内卷打工人？",
    9: "初二孩子沉迷手游，讲道理没用，怎么开口沟通？",
    10: "孩子上幼儿园天天哭，怎么帮他度过分离焦虑？",
    11: "孩子对绘本没兴趣，怎么让他重新爱上阅读？",
    12: "青春期孩子什么都不说，怎么慢慢把关系修回来？",
    13: "高考选科物理和历史成绩差不多，从发展路径看该怎么选？",
    14: "客户总说报价高，怎么谈价格不变成纯比价？",
    15: "给导师写进度汇报邮件，怎么写得礼貌又不像流水账？",
    16: "孩子写作业变家庭战争，怎么设计一个协作流程？",
    17: "幼儿园家庭树手工，手不算巧的家长用快递盒怎么做？",
    18: "快45岁了，不懂技术的管理者怎么真正入门 AI？",
    19: "32岁想从运营转产品经理，没有科班背景怎么准备？",
    20: "33岁想搞副业，下班没什么精力，有哪些低成本方向？",
    21: "35岁职业成长到平台期，裸辞又太冒险，该怎么破局？",
    22: "面试被问冷门 App 日活怎么提升20%，怎么回答？",
    23: "下班太累对老婆说话敷衍，怎么用10分钟让她感觉被在意？",
    24: "带娃快崩溃时，怎么稳住情绪不对孩子发火？",
    25: "预算15万买家庭用车，主要接送孩子，选哪类思路？",
    26: "中年人该提前排查哪些家庭风险，才不会真出问题时太被动？",
    27: "小红书做低成本独居生活账号，第一个月怎么起号？",
    28: "年终述职自己写出来总像流水账，怎么提炼成管理者的表达？",
    29: "准备考研但每天都在内耗反复横跳，怎么做决策框架？",
    30: "刚到新公司总插不上话，怎么自然地加入同事的聊天？",
    31: "下班只想躺着，25岁上班族平日晚上怎么安排不至于太空？",
    32: "刚开始自己做饭，每天不知道吃什么，怎么做7天晚餐计划？",
    33: "刚毕业月薪8k在深圳，怎么分配才能偶尔出去玩又不太紧？",
    34: "职场新人第一次部门汇报，怎么设计结构、开头怎么稳住场子？",
    35: "发现妈妈最近记性明显变差，她又很敏感，怎么关注又不让她受伤？",
    36: "每周太多低效会议，怎么比较自然地推掉或要求提前明确目标？",
    37: "和喜欢的人聊天总是聊着聊着就断了，怎么延展话题不查户口？",
    38: "和室友作息完全不同影响睡眠，怎么开口又不把关系搞僵？",
    39: "我和爱人想50岁前有比较自由的选择权，现在该怎么测算规划？",
    40: "结婚快20年只剩孩子家务可说，怎么安排一次不尴尬的破冰约会？",
    41: "父母来帮带娃但总管太多边界模糊，怎么把边界说清楚不伤感情？",
    42: "老婆觉得我没把家里的事放心上，怎么分析她真正不爽的点再开口？",
    43: "自己拍的短视频总像流水账，怎么有叙事感和故事感？",
    44: "做了15年销售总监想转咨询顾问，人脉和经验怎么真正变成服务？",
    45: "职场里面对资历深的人不敢提不同意见，怎么安全表达？",
    46: "导师让做文献综述，几十篇论文怎么梳理成一条清晰的线？",
    47: "准备作品集，怎么整理出风格和能力，而不是像模板拼出来的？",
    48: "一开口说英语就怕出错，适合上班族的30天口语练习方案是什么？",
    49: "退休后想回老家县城住，现在就要开始准备哪些事？",
    50: "考虑跳去远程办公团队，面试时怎么判断值不值得去？",
    51: "家庭保险越看越乱，重疾医疗寿险按家庭角色怎么配置？",
    52: "女儿谈了个条件一般但踏实的对象，怎么和她聊这件事？",
    53: "妈妈又安排相亲了，怎么礼貌回应又能把节奏拖开？",
    54: "第一次装修，按开工前中收尾三个阶段，最容易被坑在哪？",
    55: "孩子爱刷短视频影响作息，怎么和孩子谈规则大人也不双标？",
    56: "怎么用 AI 整理语音备忘录，让整理结果可以直接拿去用？",
    57: "团队里90后95后00后混编，管理重点应该怎么调整？",
    58: "快45岁了，非技术背景的管理者，AI 到底能帮我做哪三件事？",
    59: "想自己搭一个家庭用 AI 助手，从哪一步开始比较合适？",
    60: "做了一年新媒体准备去读研，怎么写一封体面不官腔的离职信？",
    61: "想做一个能长期坚持的周计划系统，兼顾工作家庭运动和留白？",
    62: "完全零基础，怎么用14天学会 Excel 做表格汇总？",
    63: "带一家三口出去玩3天孩子还小，怎么安排轻松不像打仗的行程？",
    64: "之前办卡买装备都坚持不住，怎么3周从零开始不用健身房健身？",
    65: "想找老板谈加薪，每次一想到这个场景就先怂了，怎么准备？",
    66: "除了问问题，AI 还能帮学生和职场新人做哪5件实用的事？",
    67: "想把一段文字改成汪曾祺那种淡淡有味的风格，关键在哪里？",
    68: "打开表格就头大，普通家庭怎么做一个能长期维护的财务模板？",
    69: "想把多年经验做成个人品牌，课程文章咨询哪种形式起步最自然？",
    70: "怎么让 AI 帮我写周报和会议纪要，又不让人看出机器味？",
    71: "想用 AI 做一个数字分身处理邮件和消息，普通人怎么一步步搭？",
    72: "想给爸妈买礼物，什么东西能真正提升他们的生活质量？",
    73: "怎么跟父母解释我留在大城市不是虚荣，是职业机会真的差很多？",
    74: "刚毕业投品牌策划岗，怎么把自我介绍改得让人有印象？",
    75: "和朋友旅行消费观差太大，出发前怎么把规则讲清楚不伤感情？",
    76: "30多岁上班族想重新捡起英语，每天不超过30分钟怎么安排？",
    77: "销售团队这两年业绩波动大心态不稳，怎么激励而不把人逼太狠？",
    78: "怎么让 AI 整理课堂录音和读书笔记，整理成能直接复习的版本？",
    79: "市场营销专业的实习经历简历描述太普通，怎么改得更亮眼？",
    80: "团队里能力强但开会总公开反驳我的95后，怎么设计一次谈话？",
    81: "暗恋图书馆对面的男生，怎么写一张不尴尬的纸条要他的微信？",
    82: "想生二胎但一想就头大，怎么和另一半冷静讨论而不是一聊就吵？",
    83: "房东续租要涨价，怎么谈既不太硬又不显得完全没底线？",
    84: "发现自己很多消费都是情绪性的，怎么设计一个防冲动下单的机制？",
    85: "明明知道刷手机会焦虑但停不下来，怎么做7天调整方案？",
    86: "想买4000元二手相机拍 Vlog 和人像，新手推荐哪款，闲鱼怎么避坑？",
    87: "普通文科毕业生想做副业多赚两三千，有哪些现实一点的方向？",
    88: "想开始读稍微严肃一点的书，从哪些书入手不容易被劝退？",
    89: "客户回款拖了一个多月还没到，怎么催而不撕破脸以后还要合作？",
    90: "杭州内容运营和上海用户增长，工资差不多该从哪些角度选？",
    91: "有点想离开现在的城市，但不确定是真的该换还是只是逃避情绪？",
    92: "朋友劝考公我想去大厂爸妈说要稳定，各自的利弊怎么拆开分析？",
    93: "月到手1.2万还有5000房贷，工资到卡里就没了，怎么做预算方案？",
    94: "给管理层做汇报，怎么避免讲太细被跑题、又讲太粗被追问？",
    95: "爸爸血压高却特别爱吃咸菜腌肉，怎么劝他接受替代方案？",
    96: "想给老家父母装防跌倒的设备，但怕他们觉得被监视，怎么沟通？",
    97: "每天待办很多，晚上回头看真正推进的却很少，怎么改这个问题？",
    98: "第一次租房，进门先看什么，合同里最容易忽略哪些条款？",
    99: "微信里家庭群工作群私聊待办全混在一起，怎么用 AI 整理清楚？",
    100: "经常有应酬，怎么控制体重和身体指标又不让别人觉得不给面子？",
    101: "老婆产后情绪波动大有时控制不住，丈夫在高频场景下怎么回应？",
    102: "想给全职妈妈老婆买母亲节礼物，不要鲜花和包，有什么推荐？",
    103: "团建预算不高，怎么避免形式主义，有哪些不尴尬的团建方案？",
    104: "这个年纪去读 EMBA，到底值不值？",
    105: "和爱人长期忙于工作，怎么在周末找回两个人愿意聊天的感觉？",
    106: "长期久坐腰和肩颈不舒服，有没有在办公室就能做的5分钟动作？",
    107: "房贷还剩100万，手里有30万现金，提前还贷好还是留着？",
    108: "朋友圈里感觉大家都过得比我好，这种比较焦虑怎么聊聊？",
    109: "跨部门合作对方总临时改口甩锅，怎么推进事情又不被背锅？",
    110: "老板要降本增效方案，又说最好不裁员，从哪几个角度可以做？",
    111: "预算3000想一个人穷游重庆成都7天，重点是吃和氛围怎么排？",
    112: "帮我把课程论文的开头润色得更符合学术规范？",
    113: "用费曼学习法向完全不懂的人解释沉没成本谬误，怎么解释？",
    114: "计算机专业大一新生，从入门到参加竞赛的四年路线怎么规划？",
    115: "想自学视频剪辑，用什么免费软件，学习资源怎么安排顺序？",
    116: "能扮演雅思口语考官随机问我 Part 2 话题，然后给我打分吗？",
    117: "大厂外包岗和初创公司核心岗，从长期职业发展看该怎么选？",
    118: "根据我的实习经历，帮我生成数据导向、能力导向和成果导向三个版本？",
    119: "能模拟一场互联网产品经理群面吗？你出题我来答，最后帮我复盘？",
    120: "预算3000想买一部拍照好还能玩原神的手机，推荐哪款？",
    121: "独居大学生有哪些低成本容易养活的室内绿植可以推荐？",
    122: "我有点社恐，明天要参加社团破冰活动，有哪些在角落也不尴尬的话术？",
    123: "以毕业季的操场为主题，帮我写一段适合 Vlog 的文艺旁白？",
    124: "如果鲁迅先生有微博，面对今天的内卷现象他会发什么？",
    125: "帮我想三个校园背景悬疑小说的高概念设定，结合元宇宙和中式恐怖？",
    126: "这封语气强硬的跨部门邮件，怎么改成既有底线又不伤和气的版本？",
    127: "帮我做一个 AIGC 赋能传统行业的季度汇报 PPT 大纲？",
    128: "工作5年的项目经理想转 AI 产品经理，技能缺口在哪，怎么学？",
    129: "每周会议太多没时间写代码，怎么用 AI 自动生成会议纪要？",
    130: "和伴侣进入室友期，有什么具体的沟通游戏或话题能增进亲密关系？",
    131: "双方父母催生压力很大，有哪些既尊重又守住边界的高情商回应？",
    132: "夫妻年收入税后60万有一个2岁孩子，家庭资产和教育金怎么配置？",
    133: "孩子3岁脾气暴躁动不动躺地打滚，非暴力沟通怎么做？",
    134: "怎么向5岁的孩子解释什么是 AI，用讲故事或比喻的方式？",
    135: "幼儿园中班孩子，周末怎么安排低成本非电子产品的放电行程？",
    136: "帮我生成10个适合发朋友圈的中年人崩溃瞬间搞笑文案？",
    137: "请写一封来自40岁的我写给20岁自己的信，提醒哪些事不必焦虑？",
    138: "不增加预算的情况下，怎么激励那几个一直躺平的资深老员工？",
    139: "传统制造业要引入 AI 质检，可行性报告大纲和投资回报怎么写？",
    140: "团队连续两季度没达标、士气低落，季度复盘会怎么开才不是追责？",
    141: "请站在 CEO 角度，帮我写数字化转型第二阶段的董事会开场白？",
    142: "孩子高一喜欢考古但物理成绩一般，选科怎么平衡兴趣和就业面？",
    143: "发现孩子偷用压岁钱买手机打游戏成绩下滑，怎么谈话不激化矛盾？",
    144: "孩子要出国留学，行前心理建设和文化适应需要准备哪些？",
    145: "父母70岁，帮我列一份全面体检中必须包含的核心项目？",
    146: "感觉自己知识结构有些老化，推荐一份中年版书单或播客？",
    147: "当前经济周期下，家庭资产怎么配置才能兼顾流动性和抗通胀？",
    148: "想50岁实现半退休，现在该怎么测算资金缺口和副业方向？",
    149: "帮我以江湖为隐喻，写一段职场中年人知世故而不世故的散文？",
    150: "如果给20岁的自己发一条限20字的短信，包含后悔鼓励和爱，写什么？",
    151: "去云南旅游7天不想去网红景点也不想太累，怎么定制行程？",
    152: "请扮演一个毒舌但一针见血的人生导师，听我吐槽，每句结尾用古诗怼我？",
    153: "帮我把今天的焦虑感，比喻成一种天气、一种颜色和一种触觉？",
    154: "如果家里总爱拆家的猫会说话，被抓现行时它的内心独白是什么？",
    155: "帮我润色这段实习经历的简历描述，让 HR 觉得我既有数据思维又有创意？",
    156: "我要用 Citespace 做文献计量分析，能一步步教我参数怎么设置吗？",
    157: "帮我模拟字节跳动运营岗面试官，问我冷门 App 日活提升的问题？",
    158: "马克思异化劳动理论，怎么用大白话结合996现象解释给普通人听？",
    159: "预算3000块想穷游重庆成都7天，重点是吃和氛围，按天怎么排？",
    160: "刚毕业月薪8k在一线城市，不想买基金只保证现金流，怎么理财？",
    161: "想买二手微单预算4k主要拍 Vlog 和人像，推荐哪款，闲鱼怎么避坑？",
    162: "暗恋图书馆坐对面的男生，帮我写几句要他微信的不尴尬纸条？",
    163: "帮我想几个发疯文学风格的宿舍群名，要那种又颠又可爱的？",
    164: "如果李白是现代说唱歌手，他会怎么 diss 那些水论文的学术不端？",
    165: "团队里能力强但总在公开场合反驳我的95后下属，怎么跟他谈？",
    166: "年终述职怎么把跨部门项目业绩提炼成资源整合和抗压能力的表达？",
    167: "孩子3岁进入反抗期，怎么温柔而坚定地回应，不靠吼也不靠哄？",
    168: "想给全职妈妈老婆买母亲节礼物预算2000，不要鲜花和包有什么推荐？",
    169: "幼儿园要交家庭树手工，用家里快递盒和落叶，手残党怎么做出来？",
    170: "长期久坐腰肌劳损，有没有适合在办公室做的5分钟康复训练动作？",
    171: "房贷还剩100万手里有30万闲钱，提前还贷还是留着做备用金？",
    172: "怎么设计一个恋爱积分打卡表，把做家务带娃量化又不让她觉得伤感情？",
    173: "如果《水浒传》里宋江是互联网大厂 CTO，管理108将的 OKR 怎么写？",
    174: "做了15年销售总监想转型咨询顾问，过去的人脉资源怎么包装成产品？",
    175: "老板让出一个不裁员但能提升人效30%的方案，从哪几个角度做？",
    176: "快45岁了总听不懂 AI 黑话，不是技术出身的管理者 AI 到底能帮什么？",
    177: "孩子上初二沉迷手机游戏成绩下滑，跟他讲道理就嫌烦，怎么沟通？",
    178: "高考选科物理和历史成绩差不多，结合 AI 对行业的冲击该怎么选？",
    179: "在上海夫妻年收80万有两套房，想50岁提前退休，每年需要存多少？",
    180: "想给老家父母装防跌倒监控，但又怕他们觉得被监视，怎么沟通？",
    181: "结婚快20年和爱人除了孩子没共同话题，怎么安排一次破冰约会？",
    182: "如果《红楼梦》贾府搞数字化转型，王熙凤会怎么用大数据管理 KPI？",
    183: "怎么用 AI 做一个数字分身，让它替我回复简单的邮件和微信消息？",
    184: "帮我把这段描写夏天的文字，改成汪曾祺那种淡而有味的风格？",
    185: "如果你是存在主义哲学家，怎么看待中年人努力边际效益递减的无意义感？",
    186: "大二学计算机感觉跟不上，怎么制定零基础 Python 的三个月学习计划？",
    187: "马上要考英语四级，听力阅读总是错很多，怎么做一套完整的备考方案？",
    188: "毕业论文选题是短视频对大学生消费习惯的影响，文献综述和结构怎么搭？",
    189: "下周要参加新媒体运营实习面试，面试官会问什么，自我介绍怎么说？",
    190: "第一次租房，签合同时必须注意哪些条款，看房时要检查什么细节？",
    191: "和最好的朋友因小事闹矛盾了，想主动和好，怎么开口才真诚不尴尬？",
    192: "想利用课余时间做副业，有哪些适合大学生的线上兼职，怎么开始？",
    193: "经常熬夜复习白天精神很差，怎么调整作息又不影响学习？",
    194: "想拍校园日常类短视频发抖音，帮我设计3个可直接拍摄的短视频脚本？",
    195: "喜欢一个人很久了，要不要表白，怎么表白比较自然不尴尬？",
    196: "年底写年度工作总结和明年计划，怎么搭建专业的述职报告框架？",
    197: "宝宝刚满1岁总是半夜哭闹不好好吃饭，可能是什么原因，怎么处理？",
    198: "和婆婆住在一起带孩子，育儿观念不同经常矛盾，怎么沟通不伤和气？",
    199: "月薪到手1万要还房贷，总是存不下钱，怎么做月度收支规划？",
    200: "长期久坐腰酸背痛颈椎不舒服，没时间健身，每天15分钟拉伸怎么做？",
    201: "结婚纪念日快到了，预算500元以内，有哪些有心意的浪漫小方案？",
    202: "同事总把不属于我的工作推过来，怎么委婉拒绝又不得罪人？",
    203: "想换工作但市场不好怕裸辞，在职跳槽需要注意什么，简历怎么写？",
    204: "夫妻因为家务带娃钱的问题经常吵架，感情越来越淡，怎么改善沟通？",
    205: "新家装修，怕被坑增项，哪些地方该省钱，哪些地方不能省？",
    206: "团队积极性不高执行力差，开会布置的任务经常拖延，有什么管理方法？",
    207: "孩子上初中叛逆期回家就关门不说话，怎么建立信任和平等交流？",
    208: "想带父母做体检，体检套餐怎么选，哪些项目必须做哪些是过度检查？",
    209: "想给父母配保险，市面上产品太多，老年人适合买哪种类型？",
    210: "在公司遇到职业瓶颈上升空间有限，是继续深耕还是找副业转型更稳妥？",
    211: "家里房贷孩子教育老人赡养开支都大，想做稳健理财，怎么配置资产？",
    212: "和伴侣长期忙于工作感情越来越淡，有什么重建亲密关系的实用建议？",
    213: "同学聚会让我上台说几句，怎么写一段简短真诚又不太客套的发言？",
    214: "想培养一个长期坚持的爱好缓解工作压力，中年人零基础从哪里入门？",
    215: "请写一个以深夜便利店为场景，温暖治愈风格的300字小故事？",
    216: "想开一家温馨简约的社区咖啡店，帮我起10个店名各配一句 slogan？",
    217: "帮我把一段很普通的日常心情文案，改写成高级克制有氛围感的版本？",
    218: "请以'如果时间可以暂停一天'为主题，写一段脑洞大开的创意短文？",
    219: "帮我写一篇公司公众号节日祝福推文，正式但不生硬，温暖又专业？",
    220: "帮我设计一段治愈系黄昏海边柔和光影风格的 AI 绘画详细关键词？",
    221: "我在写小说，帮我完善一个35岁有秘密、外冷内温的都市男主设定？",
    222: "帮我把一首经典古诗用现代白话文重新表达，保留原意像散文一样流畅？",
    223: "请写一段适合短视频结尾的成长励志文案，15秒内能读完，有力量不鸡汤？",
    224: "帮我写一段文化创意工作室的 logo 品牌理念，传递专注温暖有质感的感觉？",
}

# ── 旧 prompt rendering_name 映射 ─────────────────────────────
OLD_RENDERING_NAMES = {
    # 常识 -> life
    ("常识", 0): "读完一本书过段时间就忘了，这本书算白读了吗？",
    ("常识", 1): "为什么大多数动物都是两只眼睛两只耳朵这样成对的？",
    ("常识", 2): "新手打篮球，该重点练运球还是投篮？",
    ("常识", 3): "人完全泡在恒温水里，水温多少度才能长期生存？",
    ("常识", 4): "骑自行车，最根本的安全办法就是降低速度吗？",
    # 创作 -> creation
    ("创作", 0): "帮我写一段父子关于梦想与现实的对话，体现两代人的观念差异？",
    ("创作", 1): "以'当 AI 拥有了情感'为主题，写一个有出人意料结局的科幻短篇？",
    ("创作", 2): "帮我写一篇保湿修复面霜的小红书种草文案，含成分分析和使用体验？",
    ("创作", 3): "帮我为新开的社区精品咖啡店写三条不同风格的朋友圈推广文案？",
    ("创作", 4): "帮我策划一个面向前端开发者的线上技术分享会，主题是前端框架新趋势？",
    ("创作", 5): "为新能源汽车未来发展趋势的演讲制作一个 PPT 大纲？",
    ("创作", 6): "辩题是 AI 利大于弊，作为正方一辩帮我写一份3分钟的立论陈词？",
    # 百科 -> encyclopedia
    ("百科", 0): "科幻作品里，为什么即使有时间机器也无法改变过去？",
    ("百科", 1): "旧书翻多了，书页为什么会出现容易折断的地方？",
    ("百科", 2): "为什么人对时间流逝的感知差异会这么强烈？",
    ("百科", 3): "植物能利用月夜里微弱的月光进行光合作用吗？",
    ("百科", 4): "深海生物是怎么适应极端压力环境的，身体有哪些特别的演化？",
    ("百科", 5): "生命的起源为什么常常是在高温高压的条件下形成的？",
    ("百科", 6): "鲸鱼潜水为什么能保持这么长时间的呼吸？",
    # 代码 -> code
    ("代码", 0): "帮我用面向对象思想设计一个银行账户类，包含存取款和线程安全？",
    ("代码", 1): "帮我实现一个 LRU 缓存，解释它用什么数据结构，get 和 put 怎么做？",
    ("代码", 2): "用通俗语言解释 Docker 是什么，和传统虚拟机相比有什么区别？",
    ("代码", 3): "Python 的全局解释器锁 GIL 是什么，对多线程性能有什么影响？",
    ("代码", 4): "解释 CSS 的盒模型，content-box 和 border-box 有什么区别？",
    ("代码", 5): "解释 Trie 前缀树的原理和应用场景，用代码实现插入和前缀搜索？",
    ("代码", 6): "解释发布-订阅设计模式，用代码实现一个含 on/off/emit 的事件总线？",
    # 数学 -> mathematics
    ("数学", 0): "抛两次硬币，已知至少一次正面，两次都正面的概率是多少？",
    ("数学", 1): "笼子里有鸡和兔子，5个头16只脚，各有多少只？",
    ("数学", 2): "用反证法证明根号2是无理数，步骤怎么写？",
    ("数学", 3): "写出贝叶斯定理的公式，用医学诊断的例子解释怎么用？",
    ("数学", 4): "怎么用乘法逆元的方法解同余方程 5x ≡ 7 (mod 12)？",
    ("数学", 5): "函数极限的 ε-δ 定义是什么，用它来证明 lim(x→2)(3x-1)=5？",
    ("数学", 6): "解释群的四个基本公理，以整数加法群为例说明？",
    # 角色扮演 -> role_play
    ("角色扮演", 0): "请扮演一只傲娇猫咪'咪咪'，完全用猫的口吻和我对话？",
    ("角色扮演", 1): "请扮演一名严厉的语文老师，用恨铁不成钢的劲头点评我的作文？",
    ("角色扮演", 2): "请扮演公司 CEO，面对产品召回危机，制定战略决策并安抚各方？",
    ("角色扮演", 3): "请扮演心理咨询师，温和引导我分析焦虑来源？",
    ("角色扮演", 4): "请扮演中世纪 RPG 铁匠铺老板，用符合身份的语言和我互动？",
    ("角色扮演", 5): "请扮演科幻小说家，帮我构思'修正历史导致更糟结果'的大纲？",
    ("角色扮演", 6): "请扮演专属 AI 恋人，体贴幽默，主动关心我？",
}

# ── 补充题目（用于不足30题的分类）────────────────────────────
# 这些题目视为新题，排在对应分类内的旧题之前
EXTRA_PROMPTS = [
    # ── role_play (补至33) ────────────────────────────────────
    {
        "category": "role_play",
        "rendering_name": "请扮演资深猎头顾问，帮我分析跳槽时机和方向？",
        "prompt": "请扮演一位资深猎头顾问，我来描述我的工作背景和现状，你来帮我分析当前跳槽时机是否合适，以及转型方向的建议？",
    },
    {
        "category": "role_play",
        "rendering_name": "请扮演营养科医生，根据我的饮食习惯给改善建议？",
        "prompt": "请扮演一位营养科医生，我来告诉你我平时的饮食习惯和身体指标，你来给我制定一个切实可行的饮食改善方案？",
    },
    {
        "category": "role_play",
        "rendering_name": "请扮演铁面无情的技术面试官，对我进行面试？",
        "prompt": "请扮演一位铁面无情的后端工程师技术面试官，对我进行一场模拟面试，问题可以从基础到进阶，面试结束后给我总体评价？",
    },
    {
        "category": "role_play",
        "rendering_name": "请扮演30年后的我，给现在迷茫的自己写封信？",
        "prompt": "请扮演30年后的我，用第一人称给现在正在迷茫和焦虑中的我写一封信，聊聊哪些担心是多余的、哪些事情值得认真去做？",
    },
    {
        "category": "role_play",
        "rendering_name": "请扮演挑剔的甲方，对我的方案提各种刁钻问题？",
        "prompt": "请扮演一个挑剔的甲方客户，我来向你汇报我的产品方案，你可以随时提出各种刁钻的问题或质疑，帮我提前发现方案漏洞？",
    },
    {
        "category": "role_play",
        "rendering_name": "请扮演包拯，用断案口吻帮我分析职场是非？",
        "prompt": "请扮演古代的包拯，用断案的口吻帮我分析一个职场是非问题，把事情的来龙去脉说清楚，最后给出你的判断？",
    },
    {
        "category": "role_play",
        "rendering_name": "以鲁迅口吻写一篇关于内卷和摆烂的杂文？",
        "prompt": "请以鲁迅先生的口吻，给当代打工人写一篇关于内卷和摆烂的杂文，要有鲁迅式的犀利和讽刺，结尾带一点启发？",
    },
    {
        "category": "role_play",
        "rendering_name": "假如你是苏格拉底，用反问法帮我想清楚一个决定？",
        "prompt": "假如你是苏格拉底，请用苏格拉底式的连续追问帮我想清楚一个人生决定，不要直接给结论，只负责问问题，让我自己想清楚？",
    },
    {
        "category": "role_play",
        "rendering_name": "请扮演不留情面的出版编辑，帮我评审这篇文章？",
        "prompt": "请扮演一个不留情面的资深出版编辑，帮我评审一篇文章，直接指出最致命的几个问题，不需要客气，越犀利越有帮助？",
    },
    {
        "category": "role_play",
        "rendering_name": "请扮演商务谈判教练，模拟一次和甲方谈价格的场景？",
        "prompt": "请扮演一个经验丰富的商务谈判教练，陪我模拟一次和甲方谈合同价格的场景，你先扮演甲方，我来谈，谈完后你给我复盘？",
    },
    {
        "category": "role_play",
        "rendering_name": "请扮演孔子，用论语风格回应我的职场困惑？",
        "prompt": "请扮演孔子，用论语式的简短语言回应我今天遇到的职场困惑，每条建议可以结合一句原典，然后用现代话解释应用场景？",
    },
    {
        "category": "role_play",
        "rendering_name": "请扮演犀利的 PM mentor，帮我拆解这个产品需求？",
        "prompt": "请扮演一个犀利的产品经理 mentor，用他会说的方式帮我拆解这个产品需求，包括用户是谁、核心诉求是什么、可以砍掉什么？",
    },
    # ── encyclopedia (补至32) ─────────────────────────────────
    {
        "category": "encyclopedia",
        "rendering_name": "黑洞的事件视界是什么，越过去真的什么都逃不出来吗？",
        "prompt": "黑洞的事件视界到底是什么？越过了之后真的什么都逃不出来吗，包括光？请用相对论的基本逻辑解释一下？",
    },
    {
        "category": "encyclopedia",
        "rendering_name": "人为什么在梦里会突然坠落感惊醒？",
        "prompt": "人为什么在梦里会突然产生坠落感然后惊醒？这种坠落感是怎么产生的，有没有科学解释？",
    },
    {
        "category": "encyclopedia",
        "rendering_name": "量子纠缠是什么，两个粒子真的能瞬间影响彼此吗？",
        "prompt": "量子纠缠到底是什么意思？两个粒子真的可以瞬间影响彼此吗，这不就超过光速了？请帮我解释清楚这里的物理逻辑？",
    },
    {
        "category": "encyclopedia",
        "rendering_name": "记忆是怎么存在大脑里的，为什么有些事很快就忘？",
        "prompt": "记忆是怎么存储在大脑里的？为什么有些事情记了很久，有些事情却很快忘掉？短期记忆和长期记忆的机制有什么不同？",
    },
    {
        "category": "encyclopedia",
        "rendering_name": "安慰剂效应是真实存在的吗，它的机制是什么？",
        "prompt": "安慰剂效应是真实存在的吗？吃了没有任何成分的药片真的能让人感觉好一点吗？它背后的作用机制是什么？",
    },
    {
        "category": "encyclopedia",
        "rendering_name": "地球磁场为什么会反转，上一次反转发生了什么？",
        "prompt": "地球磁场为什么会发生反转？历史上已经反转过多少次？上一次反转的时候对地球上的生物有什么影响？",
    },
    {
        "category": "encyclopedia",
        "rendering_name": "为什么飞机在高空飞行反而不容易被雷击？",
        "prompt": "为什么飞机在高空飞行反而不容易被雷击？雷电不是应该更容易击中高处的东西吗？这背后的物理原理是什么？",
    },
    {
        "category": "encyclopedia",
        "rendering_name": "说不同语言的人，看世界的方式真的会不一样吗？",
        "prompt": "语言真的会影响思维方式吗？说中文和说英文的人对时间、颜色、空间的感知真的会不同吗？这方面有哪些有意思的研究？",
    },
    {
        "category": "encyclopedia",
        "rendering_name": "章鱼明明是色盲，为什么还能完美变色伪装？",
        "prompt": "章鱼是如何实现变色伪装的？它们被证实是色盲，但伪装效果却极好，这个矛盾是怎么解释的？",
    },
    {
        "category": "encyclopedia",
        "rendering_name": "绝对音感是天生的还是后天训练出来的？",
        "prompt": "绝对音感到底是天生遗传的，还是后天可以通过训练获得的？为什么有些人天生就有，而大多数人怎么练都练不出来？",
    },
    {
        "category": "encyclopedia",
        "rendering_name": "进化论里适者生存，弱小的物种为什么没被淘汰完？",
        "prompt": "进化论里'适者生存'是什么意思？如果强者淘汰弱者，为什么现实中仍然有那么多体型微小或能力看起来很弱的生物存在？",
    },
    {
        "category": "encyclopedia",
        "rendering_name": "肠道菌群对大脑有什么影响，肠脑真的有关联？",
        "prompt": "人体内的肠道菌群对大脑和情绪有什么影响？肠道和大脑之间存在什么联系，这条通路是怎么工作的？",
    },
    {
        "category": "encyclopedia",
        "rendering_name": "什么是费米悖论，宇宙那么大为什么找不到外星人？",
        "prompt": "什么是费米悖论？宇宙有那么多类地行星，统计上应该存在外星文明，但为什么我们一直没有找到它们？目前有哪些主流解释？",
    },
    {
        "category": "encyclopedia",
        "rendering_name": "为什么有人喝酒脸不红，有人一喝就红，机制是什么？",
        "prompt": "为什么有的人喝酒脸不红，有的人一喝就红？背后的基因和代谢机制是什么？脸红的人喝酒风险真的更高吗？",
    },
    {
        "category": "encyclopedia",
        "rendering_name": "多巴胺和内啡肽有什么区别，刷手机和运动上瘾一样吗？",
        "prompt": "多巴胺和内啡肽有什么区别？刷手机上瘾和运动上瘾在神经机制上是一样的吗？为什么明明知道刷手机没意义还停不下来？",
    },
    {
        "category": "encyclopedia",
        "rendering_name": "大脑的神经可塑性是什么，成年后大脑还能改变吗？",
        "prompt": "大脑的神经可塑性是什么意思？成年之后大脑结构还能发生改变吗？什么样的行为或训练能真正改变大脑的连接方式？",
    },
    {
        "category": "encyclopedia",
        "rendering_name": "我们看到的星星，可能已经不存在了是真的吗？",
        "prompt": "光年是距离单位，那我们看到的星星发出的光是几百年甚至几千年前的？这意味着我们现在看到的星星可能已经死亡了？这怎么理解？",
    },
    {
        "category": "encyclopedia",
        "rendering_name": "人类为什么会脸红，脸红有什么进化意义？",
        "prompt": "人类为什么会脸红？脸红是几乎在所有人类文化中都存在的现象，但其他动物很少有，这对进化来说有什么意义？",
    },
    {
        "category": "encyclopedia",
        "rendering_name": "古代人不刷牙，为什么牙齿问题没现代人多？",
        "prompt": "为什么古代人没有牙刷和牙膏，反而考古发现的牙齿状态比现代人好很多？是饮食的问题还是有其他原因？",
    },
    {
        "category": "encyclopedia",
        "rendering_name": "薛定谔的猫是什么，这个实验想说明什么？",
        "prompt": "薛定谔的猫这个思想实验到底是什么意思？一只猫怎么可能同时是死的和活的？它是在讽刺量子力学还是在说明什么深刻的物理原理？",
    },
    {
        "category": "encyclopedia",
        "rendering_name": "为什么有些人觉得某些音乐会让自己起鸡皮疙瘩？",
        "prompt": "为什么听某些音乐会让人起鸡皮疙瘩甚至热泪盈眶？这种现象叫什么，背后有什么神经科学的解释？不是所有人都会有这种反应吗？",
    },
    # ── code (补至32) ─────────────────────────────────────────
    {
        "category": "code",
        "rendering_name": "什么是 RESTful API，和 GraphQL 相比各有什么优缺点？",
        "prompt": "什么是 RESTful API？它的设计原则是什么？和 GraphQL 相比，在什么场景下各自更有优势？",
    },
    {
        "category": "code",
        "rendering_name": "TCP 三次握手和四次挥手是什么，为什么不能两次握手？",
        "prompt": "TCP 三次握手和四次挥手的过程是什么？为什么连接建立需要三次，而不是两次就够了？挥手为什么要四次？",
    },
    {
        "category": "code",
        "rendering_name": "Git 的 rebase 和 merge 有什么区别，分别什么时候用？",
        "prompt": "Git 的 rebase 和 merge 有什么区别？提交历史的处理方式有什么不同？分别在什么工作场景下更合适使用？",
    },
    {
        "category": "code",
        "rendering_name": "什么是微服务架构，相比单体应用有什么优势和挑战？",
        "prompt": "什么是微服务架构？它和单体应用相比有哪些优势？在实际落地时通常会遇到哪些挑战，比如服务通信、部署、监控等？",
    },
    {
        "category": "code",
        "rendering_name": "React 的 Hooks 原理是什么，useState 内部怎么工作的？",
        "prompt": "React 的 Hooks 原理是什么？为什么 Hooks 不能在条件语句里使用？useState 内部是怎么实现状态存储和更新的？",
    },
    {
        "category": "code",
        "rendering_name": "什么是跨站脚本攻击 XSS，如何在前后端分别防御？",
        "prompt": "什么是跨站脚本攻击 XSS？它有哪几种类型，分别是怎么被利用的？前端和后端各自应该怎么防御？",
    },
    {
        "category": "code",
        "rendering_name": "时间复杂度是什么，常见排序算法各是哪个级别？",
        "prompt": "时间复杂度和空间复杂度是什么？O(n log n) 和 O(n²) 的排序算法分别是哪些？什么场景下该选哪种？",
    },
    {
        "category": "code",
        "rendering_name": "帮我设计一个短链接系统的数据库结构和核心接口？",
        "prompt": "帮我设计一个短链接系统，需要包含数据库表结构、生成短链的核心算法（如何避免冲突），以及重定向接口的设计？",
    },
    {
        "category": "code",
        "rendering_name": "JWT 鉴权是什么，和 Session Cookie 方案有什么不同？",
        "prompt": "JWT 鉴权是什么？它的结构是怎样的？和传统的 Session Cookie 方案相比，在安全性、状态管理和跨域处理上有什么不同？",
    },
    {
        "category": "code",
        "rendering_name": "用 SQL 查出每个用户最近一次下单的记录？",
        "prompt": "有一张订单表（order_id, user_id, order_time, amount），请用 SQL 查出每个用户最近一次下单的完整记录，写出查询语句并解释思路？",
    },
    {
        "category": "code",
        "rendering_name": "async/await 在 JavaScript 里怎么工作，和 Promise 是什么关系？",
        "prompt": "async/await 在 JavaScript 里是怎么工作的？它和 Promise 是什么关系？背后的事件循环机制是怎么处理异步任务的？",
    },
    {
        "category": "code",
        "rendering_name": "怎么给 Python 项目写单元测试，pytest 基本用法是什么？",
        "prompt": "怎么给 Python 项目写单元测试？pytest 的基本使用方式是什么？如何 mock 外部依赖，以及如何组织测试文件的目录结构？",
    },
    {
        "category": "code",
        "rendering_name": "怎么用 Python 批量处理 Excel 并导出汇总报告？",
        "prompt": "怎么用 Python 批量读取一个文件夹下的所有 Excel 文件，对特定列做聚合计算，然后导出一个汇总报告？请给出完整的示例代码？",
    },
    {
        "category": "code",
        "rendering_name": "用 Python 调用大模型 API 做一个带对话历史的聊天机器人？",
        "prompt": "如何用 Python 调用大语言模型的 API 做一个带对话历史的简单聊天机器人？需要怎么管理上下文、控制 token 数量不超限？",
    },
    {
        "category": "code",
        "rendering_name": "什么是 CAP 定理，分布式系统为什么无法同时满足三个条件？",
        "prompt": "什么是 CAP 定理？一致性、可用性和分区容错性分别是什么意思？为什么分布式系统无法同时满足这三个条件，现实中通常怎么取舍？",
    },
    {
        "category": "code",
        "rendering_name": "帮我写一个 Nginx 反向代理配合 Docker 部署 Web 应用的配置？",
        "prompt": "帮我写一个用 Nginx 做反向代理、配合 Docker Compose 部署一个前后端分离 Web 应用的完整配置示例，包含 nginx.conf 和 docker-compose.yml？",
    },
    {
        "category": "code",
        "rendering_name": "用 Python 写一个爬虫，抓取某个网页的所有标题和链接？",
        "prompt": "用 Python 写一个简单的爬虫，抓取指定网页上的所有 <a> 标签的文字和链接，并去掉重复的结果，输出到一个文本文件？",
    },
    # ── mathematics (补至32) ──────────────────────────────────
    {
        "category": "mathematics",
        "rendering_name": "等差数列和等比数列的求和公式分别是什么，怎么推导？",
        "prompt": "等差数列和等比数列的求和公式分别是什么？请各自推导一遍，并举例说明在实际题目中怎么用？",
    },
    {
        "category": "mathematics",
        "rendering_name": "用数学归纳法证明 1+2+...+n = n(n+1)/2？",
        "prompt": "请用数学归纳法完整证明 1+2+3+...+n = n(n+1)/2，写出归纳基础和归纳步骤的每一步？",
    },
    {
        "category": "mathematics",
        "rendering_name": "虚数单位 i 是什么，复数在现实中有什么应用？",
        "prompt": "虚数单位 i 是怎么定义的？复数和纯虚数有什么区别？复数在现实世界的工程或物理中有什么实际应用场景？",
    },
    {
        "category": "mathematics",
        "rendering_name": "线性回归最小二乘法的原理，用矩阵形式怎么表达？",
        "prompt": "线性回归的最小二乘法原理是什么？损失函数怎么定义？用矩阵形式写出参数的解析解，并解释为什么这样求最小值？",
    },
    {
        "category": "mathematics",
        "rendering_name": "蒙提霍尔问题为什么换门概率更高，用数学解释？",
        "prompt": "蒙提霍尔问题（三门问题）：选完一扇门后主持人打开一扇没有奖品的门，为什么换门的获奖概率更高？用条件概率或枚举法证明一下？",
    },
    {
        "category": "mathematics",
        "rendering_name": "泰勒展开是什么，e^x 在 x=0 处的展开式怎么推导？",
        "prompt": "泰勒展开的思想是什么？请推导 e^x 在 x=0 处的泰勒展开式，并解释收敛半径的意义？",
    },
    {
        "category": "mathematics",
        "rendering_name": "排列和组合有什么区别，公式分别是什么？",
        "prompt": "排列和组合的本质区别是什么？从 n 个元素中取 r 个，排列数和组合数的公式分别是什么，各自怎么推导出来的？",
    },
    {
        "category": "mathematics",
        "rendering_name": "矩阵的行列式是什么，2×2 和 3×3 怎么计算？",
        "prompt": "矩阵的行列式是什么？它的几何意义是什么？请给出 2×2 和 3×3 矩阵行列式的计算公式，并举例说明？",
    },
    {
        "category": "mathematics",
        "rendering_name": "素数有无穷多个，这个命题怎么证明？",
        "prompt": "请完整写出欧几里得对'素数有无穷多个'的证明过程，解释反证法在这里是如何应用的？",
    },
    {
        "category": "mathematics",
        "rendering_name": "微分和积分是什么，牛顿-莱布尼茨公式说明了什么？",
        "prompt": "微分和积分分别是什么？导数和积分的直观意义是什么？牛顿-莱布尼茨公式揭示了两者之间什么样的关系？",
    },
    {
        "category": "mathematics",
        "rendering_name": "投两次骰子，点数之和为7的概率是多少？",
        "prompt": "投掷一个公平的六面骰子两次，两次点数之和恰好为7的概率是多少？请列出样本空间并计算？",
    },
    {
        "category": "mathematics",
        "rendering_name": "正态分布是什么，3σ 原则是什么意思？",
        "prompt": "正态分布的定义和性质是什么？什么是 3σ 原则？用正态分布解释一下为什么很多自然现象都符合这个分布？",
    },
    {
        "category": "mathematics",
        "rendering_name": "平面上三点能构成三角形吗，面积怎么计算？",
        "prompt": "已知平面上三点 A(1,2)、B(3,4)、C(5,1)，这三点是否构成三角形？如果是，用向量叉积法求出这个三角形的面积？",
    },
    {
        "category": "mathematics",
        "rendering_name": "欧拉公式 e^(iπ)+1=0 为什么被称为最美公式？",
        "prompt": "欧拉公式 e^(iπ)+1=0 为什么被称为数学中最美的公式？请解释公式中每个符号的含义，并用泰勒展开推导它的来源？",
    },
    {
        "category": "mathematics",
        "rendering_name": "解方程组：3x+2y=7，x-y=1？",
        "prompt": "用消元法和矩阵法分别解方程组：3x+2y=7，x-y=1，写出完整步骤？",
    },
    {
        "category": "mathematics",
        "rendering_name": "向量的点积和叉积分别有什么几何意义？",
        "prompt": "向量的点积和叉积分别是什么？它们各自有什么几何意义？在三维空间的实际计算中分别用来做什么？",
    },
    {
        "category": "mathematics",
        "rendering_name": "用积分计算 f(x)=x² 在 [0,3] 上的面积？",
        "prompt": "请用定积分计算函数 f(x)=x² 在区间 [0,3] 上与 x 轴围成的面积，写出完整计算步骤？",
    },
    {
        "category": "mathematics",
        "rendering_name": "ln 和 log₁₀ 有什么区别，换底公式是什么？",
        "prompt": "自然对数 ln 和常用对数 log₁₀ 有什么区别？换底公式是什么，怎么推导出来的？请举例说明换底公式在实际计算中的用法？",
    },
    {
        "category": "mathematics",
        "rendering_name": "合格率60%，取5件恰好3件合格的概率是多少？",
        "prompt": "一批产品的合格率为60%，随机抽取5件，恰好有3件合格品的概率是多少？请用二项分布公式计算，并写出推导过程？",
    },
    {
        "category": "mathematics",
        "rendering_name": "傅里叶变换是什么，在信号处理中能做什么？",
        "prompt": "傅里叶变换的数学思想是什么？为什么任何信号都可以分解成正弦波的叠加？在音频处理或通信中有哪些典型的应用？",
    },
    {
        "category": "mathematics",
        "rendering_name": "两个奇数的和一定是偶数，怎么用数学语言证明？",
        "prompt": "请用严格的数学语言证明：任意两个奇数的和一定是偶数，写出假设、推导和结论的完整过程？",
    },
    {
        "category": "mathematics",
        "rendering_name": "f(x)=x³-3x 的极大值和极小值怎么求？",
        "prompt": "请求函数 f(x)=x³-3x 的极大值和极小值，包括求导、令导数为零、判断极值类型的完整步骤？",
    },
    {
        "category": "mathematics",
        "rendering_name": "集合的并集交集补集是什么，韦恩图怎么表示？",
        "prompt": "集合的并集、交集和补集分别是什么定义？用韦恩图如何直观表示它们？请结合具体数字集合举例说明？",
    },
    {
        "category": "mathematics",
        "rendering_name": "哥德巴赫猜想是什么，为什么至今无法被完全证明？",
        "prompt": "哥德巴赫猜想的内容是什么？人类在证明它上取得了哪些进展（比如陈景润的工作）？为什么这个看起来简单的命题至今还没有被完全证明？",
    },
    {
        "category": "mathematics",
        "rendering_name": "数学归纳法是什么，和普通归纳推理有什么不同？",
        "prompt": "数学归纳法是什么？它包含哪两个步骤？和日常生活中的归纳推理相比，为什么数学归纳法可以严格证明无限多的情况？",
    },
]


def load_new_prompts():
    with open(NEW_PROMPTS_FILE, encoding="utf-8") as f:
        return json.load(f)


def load_old_prompts():
    with open(OLD_PROMPTS_FILE, encoding="utf-8") as f:
        data = json.load(f)
    results = []
    for cat in data["zh"]["chat"]:
        cat_name = cat["name"]
        category = OLD_CATEGORY_MAP[cat_name]
        for idx, item in enumerate(cat["items"]):
            prompt_text = item.get("prompt") or item["display"]
            rendering_name = OLD_RENDERING_NAMES.get((cat_name, idx), item["display"])
            results.append({
                "category": category,
                "rendering_name": rendering_name,
                "prompt": prompt_text.strip(),
                "score": 0,
                "source": "old",
            })
    return results


def build_new_records(new_prompts):
    records = []
    for idx, prompt_text in enumerate(new_prompts):
        prompt_text = prompt_text.strip()
        category = get_new_category(idx)
        rendering_name = NEW_RENDERING_NAMES.get(idx)
        if rendering_name is None:
            raise ValueError(f"Missing rendering_name for new prompt index {idx}: {prompt_text[:40]}...")
        records.append({
            "category": category,
            "rendering_name": rendering_name,
            "prompt": prompt_text,
            "score": 0,
            "source": "new",
        })
    return records


def build_extra_records():
    records = []
    for item in EXTRA_PROMPTS:
        records.append({
            "category": item["category"],
            "rendering_name": item["rendering_name"],
            "prompt": item["prompt"].strip(),
            "score": 0,
            "source": "extra",
        })
    return records


def deduplicate(new_records, extra_records, old_records):
    """先新 prompt，再 extra，再旧 prompt，按 prompt.strip() 去重"""
    seen = set()
    result = []
    for rec in new_records + extra_records + old_records:
        key = rec["prompt"].strip()
        if key not in seen:
            seen.add(key)
            result.append(rec)
    return result


QUESTION_PATTERNS = [
    "怎么", "什么", "为什么", "多少", "是否", "如何",
    "吗", "呢", "哪", "值不值", "要不要", "能不能",
    "是不是", "真的", "有没有", "会不会", "该不该", "还是",
]


def fix_rendering_name(name):
    """如果 rendering_name 以问号结尾但不含任何问词，则去掉末尾问号。"""
    if not name.endswith("？"):
        return name
    if any(p in name for p in QUESTION_PATTERNS):
        return name
    return name[:-1]


def assemble(records):
    cat_display = {cat: display for cat, display in CATEGORIES_ORDER}
    buckets = {cat: [] for cat, _ in CATEGORIES_ORDER}

    for rec in records:
        cat = rec["category"]
        buckets[cat].append({
            "rendering_name": fix_rendering_name(rec["rendering_name"]),
            "prompt": rec["prompt"],
            "score": rec["score"],
            "source": rec["source"],
        })

    output = []
    for cat, display in CATEGORIES_ORDER:
        items = buckets[cat]
        new_items = [i for i in items if i["source"] != "old"]
        old_items = [i for i in items if i["source"] == "old"]
        final_items = []
        for item in new_items + old_items:
            final_items.append({
                "rendering_name": item["rendering_name"],
                "prompt": item["prompt"],
                "score": item["score"],
            })
        output.append({
            "category": cat,
            "display_name": display,
            "items": final_items,
        })
    return output


def main():
    check_mode = "--check" in sys.argv

    new_prompts = load_new_prompts()
    old_records = load_old_prompts()
    new_records = build_new_records(new_prompts)
    extra_records = build_extra_records()
    all_records = deduplicate(new_records, extra_records, old_records)

    output = assemble(all_records)
    json_str = json.dumps(output, ensure_ascii=False, indent=2) + "\n"

    # ── 统计 ──
    total = sum(len(cat["items"]) for cat in output)
    print(f"总条目数: {total}")
    for cat in output:
        source_bucket = [rec for rec in all_records if rec["category"] == cat["category"]]
        n_new = sum(1 for i in source_bucket if i["source"] != "old")
        n_old = sum(1 for i in source_bucket if i["source"] == "old")
        print(f"  {cat['category']:15s} ({cat['display_name']:4s}): {len(cat['items']):3d} 条 (新{n_new} + 旧{n_old})")

    # ── 验证 ──
    all_prompts = [item["prompt"] for cat in output for item in cat["items"]]
    if len(all_prompts) != len(set(p.strip() for p in all_prompts)):
        print("ERROR: 存在重复 prompt!", file=sys.stderr)
        sys.exit(1)

    empty_names = [item for cat in output for item in cat["items"] if not item["rendering_name"]]
    if empty_names:
        print(f"ERROR: {len(empty_names)} 个空 rendering_name!", file=sys.stderr)
        sys.exit(1)

    min_count = min(len(cat["items"]) for cat in output)
    if min_count < 30:
        small = [c["category"] for c in output if len(c["items"]) < 30]
        print(f"ERROR: 以下分类不足30题: {small}", file=sys.stderr)
        sys.exit(1)

    bad_score = [item for cat in output for item in cat["items"] if item["score"] != 0]
    if bad_score:
        print(f"ERROR: {len(bad_score)} 个 score 不为 0!", file=sys.stderr)
        sys.exit(1)

    if check_mode:
        if os.path.exists(OUTPUT_FILE):
            with open(OUTPUT_FILE, encoding="utf-8") as f:
                existing = f.read()
            if existing == json_str:
                print("CHECK PASSED: 文件内容一致")
                sys.exit(0)
            else:
                print("CHECK FAILED: 文件内容不一致", file=sys.stderr)
                sys.exit(1)
        else:
            print("CHECK FAILED: 输出文件不存在", file=sys.stderr)
            sys.exit(1)
    else:
        with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
            f.write(json_str)
        print(f"已写入 {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
