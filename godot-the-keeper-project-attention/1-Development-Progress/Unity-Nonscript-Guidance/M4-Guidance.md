# M4 里程碑 - Godot引擎独立操作指南

本文档记录M4里程碑中需要在Godot引擎编辑器中手动完成的配置操作。

## 概述

M4里程碑包含以下任务：
- ✅ T4.1 实现构造体数据定义
- ✅ T4.2 实现构造体效果系统
- ✅ T4.3 实现构造体状态管理
- ✅ T4.4 实现实体单位场景
- ✅ T4.5 实现虚体单位场景
- ✅ T4.6 实现构造体管理器（ConstructManager）

所有脚本文件已创建完成，但需要在Godot引擎中配置autoload单例和场景。

---

## 操作步骤

### 1. 配置ConstructManager单例

构造体管理器用于管理所有构造体实例，需要配置为autoload单例：

1. 打开Godot引擎编辑器
2. 点击菜单栏：`项目(Project)` → `项目设置(Project Settings)` → `Globals`
3. 在左侧列表中选择 `Autoload` 标签页
4. 点击 `路径(Path)` 列下的输入框，输入：`res://scripts/managers/ConstructManager.gd`
5. 在 `节点名称(Node Name)` 列下输入：`ConstructManager`
6. 确保 `单例(Singleton)` 选项已勾选
7. 点击 `添加(Add)` 按钮

**重要提示**：
- ConstructManager会自动管理所有注册的实体和虚体
- 构造体需要在初始化后调用ConstructManager的注册方法

### 2. 完善Entity和Virtual场景

#### 2.1 Entity场景

1. 打开 `scenes/entities/Entity.tscn` 场景
2. 确认根节点 `Entity` 已附加 `scripts/entities/Entity.gd` 脚本
3. 为 `Sprite2D` 节点添加纹理（可以在Inspector中设置）
4. 可选：添加 `RangeIndicator` 子节点用于显示影响范围（可以使用CircleShape2D或Line2D）

#### 2.2 Virtual场景

1. 打开 `scenes/entities/Virtual.tscn` 场景
2. 确认根节点 `Virtual` 已附加 `scripts/entities/Virtual.gd` 脚本
3. 配置 `GPUParticles2D` 节点的粒子效果（可以在Inspector中设置）
4. 可选：添加 `RangeIndicator` 子节点用于显示影响范围

### 3. 验证构造体系统

运行游戏，测试以下功能：

1. **检查ConstructManager初始化**：
   - 游戏启动后，ConstructManager应该自动初始化
   - 查看控制台日志，确认初始化成功

2. **测试实体创建**：
   ```gdscript
   # 创建实体数据
   var entity_data = EntityData.new("entity_001", "测试实体", 1, Vector2i(5, 5))
   entity_data.effect_range = 2
   entity_data.trigger_probability = 0.8
   
   # 创建实体场景
   var entity_scene = preload("res://scenes/entities/Entity.tscn")
   var entity = entity_scene.instantiate()
   entity.initialize(entity_data)
   
   # 注册到管理器
   ConstructManager.register_entity(entity)
   
   # 添加到场景树
   add_child(entity)
   ```

3. **测试虚体创建**：
   ```gdscript
   # 创建虚体数据
   var virtual_data = VirtualData.new("virtual_001", "测试虚体", 1, 10.0, Vector2i(10, 10))
   virtual_data.effect_range = 3
   virtual_data.trigger_probability = 0.6
   
   # 创建虚体场景
   var virtual_scene = preload("res://scenes/entities/Virtual.tscn")
   var virtual = virtual_scene.instantiate()
   virtual.initialize(virtual_data)
   
   # 注册到管理器
   ConstructManager.register_virtual(virtual)
   
   # 添加到场景树
   add_child(virtual)
   ```

4. **测试效果系统**：
   ```gdscript
   # 创建伤害效果
   var damage_effect = DamageEffect.new(10.0)
   damage_effect.set_check_result_modifier(Constants.CHECK_RESULT_CRITICAL_SUCCESS, 5.0)
   damage_effect.set_check_result_modifier(Constants.CHECK_RESULT_CRITICAL_FAILURE, -5.0)
   
   # 添加到实体
   entity.add_effect(damage_effect)
   ```

5. **测试查询接口**：
   ```gdscript
   # 查询位置上的构造体
   var constructs = ConstructManager.get_constructs_at_position(Vector2i(5, 5))
   
   # 查询范围内的构造体
   var constructs_in_range = ConstructManager.get_constructs_in_range(Vector2i(5, 5), 3)
   
   # 查询影响指定位置的构造体
   var affecting = ConstructManager.get_constructs_affecting_position(Vector2i(6, 6))
   ```

---

## 文件清单

M4里程碑创建的文件：

### 数据类
- `scripts/data/ConstructData.gd` - 构造体数据基类
- `scripts/data/EntityData.gd` - 实体数据类
- `scripts/data/VirtualData.gd` - 虚体数据类

### 系统
- `scripts/systems/ConstructEffect.gd` - 构造体效果基类
- `scripts/systems/effects/DamageEffect.gd` - 伤害效果
- `scripts/systems/effects/SanityEffect.gd` - 理智损失效果
- `scripts/systems/effects/MovementEffect.gd` - 移动阻碍效果
- `scripts/systems/effects/StatusEffect.gd` - 状态异常效果
- `scripts/systems/ConstructState.gd` - 构造体状态管理

### 实体
- `scripts/entities/Entity.gd` - 实体脚本
- `scenes/entities/Entity.tscn` - 实体场景
- `scripts/entities/Virtual.gd` - 虚体脚本
- `scenes/entities/Virtual.tscn` - 虚体场景

### 管理器
- `scripts/managers/ConstructManager.gd` - 构造体管理器单例

---

## 使用示例

### 创建并注册实体

```gdscript
# 创建实体数据
var entity_data = EntityData.new("totem_001", "图腾", Constants.ENTITY_SERIAL_TOTEM, Vector2i(5, 5))
entity_data.effect_range = 2
entity_data.trigger_probability = 0.8
entity_data.movement_rule = "static"

# 添加效果
var damage_effect = DamageEffect.new(5.0)
damage_effect.set_check_result_modifier(Constants.CHECK_RESULT_CRITICAL_SUCCESS, 3.0)
entity_data.add_effect("damage", 5.0, Constants.CHECK_RESULT_SUCCESS)

# 创建实体场景
var entity_scene = preload("res://scenes/entities/Entity.tscn")
var entity = entity_scene.instantiate()
entity.initialize(entity_data)

# 添加效果到实体
entity.add_effect(damage_effect)

# 注册到管理器
ConstructManager.register_entity(entity)

# 添加到场景树
add_child(entity)
```

### 创建并注册虚体

```gdscript
# 创建虚体数据
var virtual_data = VirtualData.new("omen_001", "预兆", Constants.VIRTUAL_SERIAL_OMEN, 15.0, Vector2i(10, 10))
virtual_data.effect_range = 3
virtual_data.trigger_probability = 0.6

# 创建虚体场景
var virtual_scene = preload("res://scenes/entities/Virtual.tscn")
var virtual = virtual_scene.instantiate()
virtual.initialize(virtual_data)

# 添加效果
var sanity_effect = SanityEffect.new(3.0)
virtual.add_effect(sanity_effect)

# 注册到管理器
ConstructManager.register_virtual(virtual)

# 添加到场景树
add_child(virtual)
```

### 查询构造体

```gdscript
# 根据ID查询
var entity = ConstructManager.get_entity("totem_001")
var virtual = ConstructManager.get_virtual("omen_001")

# 根据位置查询
var entity_at_pos = ConstructManager.get_entity_at_position(Vector2i(5, 5))
var virtuals_at_pos = ConstructManager.get_virtuals_at_position(Vector2i(10, 10))

# 根据类型查询
var all_entities = ConstructManager.get_constructs_by_type(Constants.CONSTRUCT_TYPE_ENTITY)
var all_virtuals = ConstructManager.get_constructs_by_type(Constants.CONSTRUCT_TYPE_VIRTUAL)

# 根据范围查询
var constructs_in_range = ConstructManager.get_constructs_in_range(Vector2i(5, 5), 3)

# 查询影响指定位置的构造体
var affecting = ConstructManager.get_constructs_affecting_position(Vector2i(6, 6))
```

### 状态管理

```gdscript
# 激活构造体
entity.construct_state.change_state(Constants.CONSTRUCT_STATE_ACTIVE)

# 失效构造体
entity.construct_state.change_state(Constants.CONSTRUCT_STATE_DISABLED, 5.0)  # 5秒后恢复

# 销毁构造体
entity.destroy()
```

---

## 故障排除

### 问题1：找不到ConstructManager

**原因**：autoload未正确配置

**解决方法**：
1. 检查 `项目设置` → `Autoload` 中是否正确添加了ConstructManager单例
2. 检查路径是否正确：`res://scripts/managers/ConstructManager.gd`
3. 检查节点名称是否为 `ConstructManager`
4. 重启Godot编辑器

### 问题2：实体/虚体场景无法加载

**原因**：场景文件路径错误或节点结构不正确

**解决方法**：
1. 检查场景文件是否存在
2. 检查场景根节点是否正确附加了脚本
3. 检查场景中的子节点路径是否正确

### 问题3：效果无法应用

**原因**：目标对象没有相应的属性或方法

**解决方法**：
1. 确保目标对象有相应的属性（如health、sanity）或方法（如take_damage、lose_sanity）
2. 检查效果类型是否正确
3. 查看DebugLogger的日志输出

### 问题4：构造体无法注册

**原因**：构造体数据未正确初始化

**解决方法**：
1. 确保构造体数据（EntityData/VirtualData）已正确创建
2. 确保构造体场景已正确初始化（调用initialize方法）
3. 检查构造体ID是否唯一

---

## 下一步

M4完成后，可以继续开发：
- M5: 卡牌系统（构造体作为卡牌）
- M6: 调查员系统（与构造体交互）
- M8: 战斗与交互系统（效果触发和检定）

构造体基础系统为这些系统提供了基础支持。