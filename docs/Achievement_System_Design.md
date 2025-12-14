# 成就系统设计文档

**版本**: 1.0
**日期**: 2025-11-01

---

## 🎖️ 成就系统概述

成就系统是激励用户持续参与 ORA 生态的核心机制，通过解锁成就获得：
- **ORA Coin (OC)** 虚拟货币奖励
- **称号和徽章**
- **线下权益**（咖啡券、会员天数等）
- **五维属性加成**

---

## 🏆 成就分类体系

### 1. 五维属性成就（核心）

基于五维属性的等级和进度解锁成就。

#### 1.1 Cognition（认知）成就

| 成就名称 | 解锁条件 | 奖励 OC | 线下权益 | 属性加成 |
|---------|---------|---------|---------|---------|
| 知识启蒙者 | Cognition 达到 100 | 50 | - | - |
| 好学之徒 | Cognition 达到 300 | 100 | - | Cognition +20 |
| 智慧学者 | Cognition 达到 500 | 200 | 书店9折券 | Cognition +50 |
| 博学大师 | Cognition 达到 700 | 500 | 免费会员7天 | Cognition +100 |
| 知识传奇 | Cognition 达到 900 | 1000 | 免费会员30天 | Cognition +200 |
| 阅读马拉松 | 累计阅读打卡 100 次 | 150 | 书店8折券 | Cognition +30 |
| 学习狂人 | 单日学习时长 ≥ 8 小时 | 80 | 咖啡券 | Vitality +10 |
| 知识分享家 | 分享学习笔记 50 次 | 200 | - | Cognition +40, Sociability +20 |
| 讲座达人 | 参加知识讲座 20 次 | 300 | 免费会员7天 | Cognition +60 |
| 读书会铁粉 | 参加读书会 30 次 | 250 | - | Cognition +50, Sociability +30 |

#### 1.2 Sociability（社交）成就

| 成就名称 | 解锁条件 | 奖励 OC | 线下权益 | 属性加成 |
|---------|---------|---------|---------|---------|
| 社交新手 | Sociability 达到 100 | 50 | - | - |
| 活跃社交者 | Sociability 达到 300 | 100 | - | Sociability +20 |
| 社交达人 | Sociability 达到 500 | 200 | 活动优先权 | Sociability +50 |
| 社交大师 | Sociability 达到 700 | 500 | 免费会员7天 | Sociability +100 |
| 社交传奇 | Sociability 达到 900 | 1000 | 免费会员30天 | Sociability +200 |
| 好友收集家 | 好友数量 ≥ 50 | 150 | - | Sociability +30 |
| 社交蝴蝶 | 好友数量 ≥ 200 | 400 | - | Sociability +80, Charisma +40 |
| 活动组织者 | 组织活动 10 次 | 300 | 场地租赁9折 | Sociability +60, Charisma +30 |
| 派对之王/女王 | 组织活动 50 次 | 800 | 场地租赁免费1次 | Sociability +120, Charisma +80 |
| 聊天高手 | 有效对话 200 次 | 250 | - | Sociability +50 |

#### 1.3 Charisma（魅力）成就

| 成就名称 | 解锁条件 | 奖励 OC | 线下权益 | 属性加成 |
|---------|---------|---------|---------|---------|
| 初露魅力 | Charisma 达到 100 | 50 | - | - |
| 人气新星 | Charisma 达到 300 | 100 | - | Charisma +20 |
| 魅力之星 | Charisma 达到 500 | 200 | - | Charisma +50 |
| 魅力领袖 | Charisma 达到 700 | 500 | VIP专属活动 | Charisma +100 |
| 魅力传奇 | Charisma 达到 900 | 1000 | 免费会员30天 | Charisma +200 |
| 点赞之星 | 收到点赞 500 次 | 150 | - | Charisma +30 |
| 万人迷 | 收到点赞 5000 次 | 600 | - | Charisma +120 |
| 影响力导师 | 被添加好友（被动）100 次 | 400 | - | Charisma +80, Sociability +40 |
| 内容创作者 | 发布高质量内容（50+ 互动）10 次 | 300 | - | Charisma +60 |
| 月度之星 | 成为月度排行榜前3 | 500 | 专属称号1个月 | Charisma +100 |

#### 1.4 Vitality（活力）成就

| 成就名称 | 解锁条件 | 奖励 OC | 线下权益 | 属性加成 |
|---------|---------|---------|---------|---------|
| 活力萌芽 | Vitality 达到 100 | 50 | - | - |
| 充满活力 | Vitality 达到 300 | 100 | - | Vitality +20 |
| 活力之星 | Vitality 达到 500 | 200 | 健身课免费1次 | Vitality +50 |
| 活力大师 | Vitality 达到 700 | 500 | 健身课免费5次 | Vitality +100 |
| 活力传奇 | Vitality 达到 900 | 1000 | 免费会员30天 | Vitality +200 |
| 签到达人 | 连续签到 30 天 | 200 | 咖啡半价券×3 | Vitality +40 |
| 百日坚持 | 连续签到 100 天 | 800 | 免费会员7天 | Vitality +150 |
| 年度冠军 | 连续签到 365 天 | 3000 | 免费会员90天 | 全属性 +100 |
| 运动健将 | 累计运动 100 小时 | 300 | 运动装备9折券 | Vitality +60 |
| 铁人三项 | 跑步+健身+瑜伽各10次 | 400 | 健身课套餐8折 | Vitality +80 |
| 早起鸟 | 连续早起（7:00前签到）30天 | 250 | 早餐券×5 | Vitality +50, Reflection +25 |

#### 1.5 Reflection（自省）成就

| 成就名称 | 解锁条件 | 奖励 OC | 线下权益 | 属性加成 |
|---------|---------|---------|---------|---------|
| 觉察启蒙 | Reflection 达到 100 | 50 | - | - |
| 自省之路 | Reflection 达到 300 | 100 | - | Reflection +20 |
| 内心平静 | Reflection 达到 500 | 200 | 冥想课免费1次 | Reflection +50 |
| 觉察大师 | Reflection 达到 700 | 500 | 心理咨询免费1次 | Reflection +100 |
| 觉察传奇 | Reflection 达到 900 | 1000 | 免费会员30天 | Reflection +200 |
| 日记作家 | 写日记 100 天 | 200 | 笔记本礼品 | Reflection +40 |
| 深度思考者 | 深度日记（>200字）50 篇 | 300 | - | Reflection +60, Cognition +30 |
| 冥想修行者 | 累计冥想 50 小时 | 400 | 冥想课程套餐 | Reflection +80 |
| 目标达成者 | 完成目标复盘 30 次 | 250 | - | Reflection +50 |
| 心灵导师 | Reflection 连续7天 ≥ 700 | 500 | VIP心理工作坊 | Reflection +100 |

---

### 2. 综合成长成就

基于多维度或综合表现解锁。

| 成就名称 | 解锁条件 | 奖励 OC | 线下权益 | 属性加成 |
|---------|---------|---------|---------|---------|
| 全面发展者 | 五维属性均 ≥ 300 | 500 | 专属称号 | 全属性 +30 |
| 完美平衡 | 五维属性均 ≥ 500 | 1000 | 免费会员14天 | 全属性 +60 |
| 传奇之路 | 五维属性均 ≥ 700 | 2000 | 免费会员30天 | 全属性 +100 |
| ORA 大使 | 综合评分 ≥ 800 | 3000 | 终身VIP | 全属性 +200 |
| 快速成长 | 30天内任一属性 +200 | 300 | - | 对应属性 +30 |
| 持续进步 | 90天内每天都有属性增长 | 600 | 免费会员7天 | 全属性 +40 |
| 跨界达人 | 三个属性 ≥ 600 | 800 | - | 全属性 +50 |

---

### 3. 社交互动成就

| 成就名称 | 解锁条件 | 奖励 OC | 线下权益 | 属性加成 |
|---------|---------|---------|---------|---------|
| 破冰者 | 主动发起对话 10 次 | 50 | - | Sociability +10 |
| 社交开拓者 | 主动发起对话 100 次 | 200 | - | Sociability +40 |
| 人脉大师 | 与 50 个不同的人有效对话 | 300 | - | Sociability +60, Charisma +30 |
| 活动参与者 | 参加活动 10 次 | 100 | - | Sociability +20 |
| 活动狂热粉 | 参加活动 50 次 | 400 | 活动优先权 | Sociability +80 |
| 团队协作者 | 与他人合作完成任务 20 次 | 250 | - | Sociability +50 |
| 互助之星 | 帮助其他会员 30 次 | 300 | - | Sociability +60, Charisma +30 |

---

### 4. 线下空间成就

结合 ORA 线下空间的实际场景。

| 成就名称 | 解锁条件 | 奖励 OC | 线下权益 | 属性加成 |
|---------|---------|---------|---------|---------|
| ORA 新人 | 首次进入 ORA 空间 | 30 | 欢迎饮品券 | - |
| 常客 | 进入 ORA 空间 30 次 | 150 | 咖啡半价券×3 | Vitality +20 |
| VIP 常客 | 进入 ORA 空间 100 次 | 500 | 免费会员7天 | Vitality +50 |
| 空间探索者 | 在所有区域（学习/社交/运动/冥想）打卡 | 200 | - | 全属性 +20 |
| 长期驻扎 | 单日在空间停留 ≥ 8 小时 | 100 | 免费饮品1杯 | Cognition +15 |
| 咖啡爱好者 | 购买咖啡 20 次 | 100 | 咖啡券×2 | - |
| 美食家 | 购买轻食 30 次 | 150 | 轻食9折券 | - |
| 会议专家 | 租赁会议室 10 次 | 200 | 会议室免费1小时 | Sociability +30 |

---

### 5. ExplORA 虚拟世界成就

与 ExplORA 游戏内行为关联。

| 成就名称 | 解锁条件 | 奖励 OC | 线下权益 | 属性加成 |
|---------|---------|---------|---------|---------|
| 虚拟探险家 | 探索 ExplORA 10 个场景 | 100 | - | Cognition +15 |
| 虚拟社交家 | 与 AI 角色对话 50 次 | 150 | - | Sociability +25 |
| 提示词魔法师 | 使用提示词 20 次 | 80 | - | Creativity +20（新属性？） |
| 虚拟导师 | 在 ExplORA 中帮助新玩家 10 次 | 200 | - | Sociability +40 |
| 世界连接者 | 在 ExplORA 中完成线上线下联动任务 | 300 | 免费会员3天 | 全属性 +30 |

---

### 6. 特殊成就与隐藏成就

#### 6.1 时间限定成就

| 成就名称 | 解锁条件 | 奖励 OC | 线下权益 | 属性加成 |
|---------|---------|---------|---------|---------|
| 新年新气象 | 元旦当天签到 | 100 | 新年礼包 | 全属性 +10 |
| 圣诞精灵 | 圣诞节参加活动 | 150 | 圣诞礼物 | 全属性 +15 |
| 生日快乐 | 生日当天进入空间 | 200 | 生日蛋糕券 | 全属性 +20 |
| 周年庆典 | ORA 周年庆参与 | 300 | 周年纪念品 | 全属性 +30 |

#### 6.2 隐藏成就（彩蛋）

| 成就名称 | 解锁条件 | 奖励 OC | 线下权益 | 属性加成 |
|---------|---------|---------|---------|---------|
| 夜猫子 | 凌晨2-4点签到 | 50 | - | Reflection +10 |
| 幸运儿 | 第 777 位签到的会员 | 777 | - | Charisma +77 |
| 全勤王 | 一年内无缺勤（365天签到） | 5000 | 免费会员180天 | 全属性 +200 |
| 意外发现 | 在 ExplORA 中发现隐藏彩蛋 | 300 | - | 全属性 +30 |
| 三重奏 | 同时在线下空间、ORA APP、ExplORA 中活动 | 400 | - | 全属性 +40 |

---

## 🎁 奖励系统设计

### ORA Coin (OC) 奖励分级

根据成就难度和价值分配 OC：
- **简单成就**: 30-100 OC
- **中等成就**: 100-300 OC
- **困难成就**: 300-800 OC
- **史诗成就**: 800-2000 OC
- **传奇成就**: 2000-5000 OC

### 线下权益类型

#### 1. 饮品券
- **咖啡半价券**: 适用于所有咖啡饮品
- **免费饮品券**: 任选一杯饮品（≤¥50）
- **早餐券**: 早餐套餐免费

#### 2. 服务券
- **健身课免费券**: 免费参加一次健身课程
- **冥想课免费券**: 免费参加一次冥想课程
- **会议室免费券**: 免费使用会议室1小时

#### 3. 会员时长
- **免费会员3天**: 延长会员有效期3天
- **免费会员7天**: 延长会员有效期7天
- **免费会员30天**: 延长会员有效期30天
- **免费会员90天**: 延长会员有效期90天
- **终身VIP**: 永久免费使用 ORA 所有服务

#### 4. 专属权益
- **活动优先权**: 优先报名热门活动
- **VIP专属活动**: 参加仅限VIP的高端活动
- **专属称号**: 在 APP 和 ExplORA 中显示特殊称号
- **场地租赁折扣**: 租赁场地享受折扣

### 属性加成

成就解锁后获得一次性属性加成：
- **小加成**: +10-30
- **中加成**: +40-80
- **大加成**: +100-200

---

## 📊 成就追踪与展示

### 成就进度显示

#### 在 ORA APP 中
```
成就页面布局：

┌─────────────────────────────────┐
│ 成就总览                         │
│ 已解锁: 45/200                   │
│ 完成度: 22.5%                    │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ 📖 认知成就 (8/15)               │
│ ⭐ 知识启蒙者 ✓                  │
│ ⭐ 好学之徒 ✓                    │
│ ⭐ 智慧学者 (进度: 450/500)       │
│ 🔒 博学大师 (需要 700)           │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ 💬 社交成就 (12/18)              │
│ ...                             │
└─────────────────────────────────┘
```

#### 成就卡片
```
┌───────────────────────────────────┐
│  🏆 智慧学者                      │
│                                   │
│  Cognition 达到 500              │
│  进度: █████████░ 450/500 (90%)  │
│                                   │
│  奖励:                            │
│  - 200 OC                        │
│  - 书店9折券                      │
│  - Cognition +50                 │
│                                   │
│  [ 还差 50 点 ]                   │
└───────────────────────────────────┘
```

### 成就通知

当用户解锁成就时：
1. **推送通知**: APP推送 + 短信（可选）
2. **动画效果**: 成就解锁动画（烟花、光效等）
3. **社交分享**: 可选择分享到社交媒体
4. **ExplORA同步**: 在虚拟世界中也显示成就解锁

---

## 🎮 ExplORA 中的成就集成

### 虚拟徽章展示

在 ExplORA 中，玩家的成就以**徽章**形式展示：
- **虚拟化身佩戴**: 选择最多 3 个徽章显示在化身上
- **成就墙**: 虚拟空间中的成就展示墙
- **特殊效果**: 传奇成就带有光效/粒子效果

### 成就对 AI 行为的影响

AI 角色会根据玩家的成就调整对话：
```
玩家解锁"博学大师"成就后：

AI: "听说你最近达到了博学大师的境界，真令人敬佩！能跟我分享一下你最近在学什么吗？"

玩家解锁"社交达人"成就后：

AI: "你真是这里的社交明星啊！我看到很多人都在谈论你。"
```

---

## 💾 数据库设计

### achievements 表（成就定义）

```sql
CREATE TABLE achievements (
    achievement_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(30), -- 'cognition', 'sociability', etc.
    difficulty VARCHAR(20), -- 'simple', 'medium', 'hard', 'epic', 'legendary'
    unlock_condition JSONB, -- 解锁条件（JSON格式）
    reward_oc INT DEFAULT 0,
    reward_offline TEXT, -- 线下权益描述
    attribute_bonus JSONB, -- 属性加成 {"cognition": 50, ...}
    is_hidden BOOLEAN DEFAULT FALSE,
    icon_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW()
);
```

### user_achievements 表（用户成就）

```sql
CREATE TABLE user_achievements (
    user_id UUID REFERENCES users(user_id),
    achievement_id VARCHAR(50) REFERENCES achievements(achievement_id),
    progress INT DEFAULT 0, -- 当前进度（如 450/500）
    target INT, -- 目标值（如 500）
    unlocked_at TIMESTAMP, -- 解锁时间（NULL表示未解锁）
    is_claimed BOOLEAN DEFAULT FALSE, -- 是否已领取奖励
    PRIMARY KEY (user_id, achievement_id)
);
```

### achievement_logs 表（成就日志）

```sql
CREATE TABLE achievement_logs (
    log_id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(user_id),
    achievement_id VARCHAR(50) REFERENCES achievements(achievement_id),
    action VARCHAR(20), -- 'progress', 'unlock', 'claim'
    old_progress INT,
    new_progress INT,
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🔌 API 接口

### 1. 获取用户成就列表

```http
GET /api/v1/achievements/{user_id}

Query Parameters:
- category: (optional) 按类别过滤
- unlocked: (optional) true/false

Response:
{
  "user_id": "uuid",
  "total_achievements": 200,
  "unlocked_count": 45,
  "completion_rate": 22.5,
  "achievements": [
    {
      "achievement_id": "cognition_lv3",
      "name": "智慧学者",
      "category": "cognition",
      "progress": 450,
      "target": 500,
      "is_unlocked": false,
      "reward_oc": 200,
      "reward_offline": "书店9折券",
      "attribute_bonus": {"cognition": 50}
    },
    ...
  ]
}
```

### 2. 检查成就进度更新

```http
POST /api/v1/achievements/check

Request:
{
  "user_id": "uuid",
  "trigger": "attribute_update", // 或 "action"
  "data": {
    "attribute": "cognition",
    "new_value": 500
  }
}

Response:
{
  "newly_unlocked": [
    {
      "achievement_id": "cognition_lv3",
      "name": "智慧学者",
      "reward_oc": 200,
      "reward_offline": "书店9折券"
    }
  ],
  "progress_updated": [
    {
      "achievement_id": "cognition_lv4",
      "old_progress": 500,
      "new_progress": 500,
      "target": 700
    }
  ]
}
```

### 3. 领取成就奖励

```http
POST /api/v1/achievements/claim

Request:
{
  "user_id": "uuid",
  "achievement_id": "cognition_lv3"
}

Response:
{
  "success": true,
  "rewards": {
    "oc_added": 200,
    "new_oc_balance": 1450,
    "offline_benefit": {
      "type": "coupon",
      "name": "书店9折券",
      "code": "BOOK90-XXXX"
    },
    "attributes_added": {
      "cognition": 50
    }
  }
}
```

---

## 🧪 测试与调优

### 成就难度平衡

根据 Beta 测试数据调整：
- **解锁率**: 每个成就在30天内的解锁率
  - 简单成就: 60-80%
  - 中等成就: 30-50%
  - 困难成就: 10-20%
  - 史诗成就: 3-8%
  - 传奇成就: <2%

### 奖励价值平衡

确保奖励与成就难度匹配：
- **OC 价值**: 1 OC ≈ ¥0.1（根据商业模式调整）
- **线下权益价值**: 与 OC 等值或略高

### 用户参与度监控

- **成就查看率**: 用户是否经常查看成就页面
- **奖励领取率**: 解锁成就后的领取率
- **激励效果**: 成就对用户行为的引导作用

---

## 🎊 总结

成就系统通过以下方式增强 ORA 生态：

1. **量化目标**: 为用户提供明确的短期和长期目标
2. **持续激励**: 通过分级奖励保持用户参与动力
3. **社交荣誉**: 成就徽章成为社交货币
4. **商业闭环**: 虚拟货币和线下权益形成商业闭环
5. **虚实联动**: ORA APP 与 ExplORA 成就同步

**下一步**: 设计虚拟货币系统和线下权益管理机制。

---

**最后更新**: 2025-11-01
