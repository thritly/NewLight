using Godot;
//using System;
//using static Menu;

// partial 部分的类定义，允许将类的实现分散在多个文件中。这里的 Pet 类继承自 Area2D，表示一个 2D 区域节点。
public partial class Pet : Menu
{
    private AnimatedSprite2D animated_sprite;
    private bool dragging = false;
    private bool is_hovering = false;
    private Vector2 drag_offset = Vector2.Zero;
    private Vector2 drag_start_mouse = Vector2.Zero;      // 鼠标按下时的全局坐标
    private Vector2I drag_start_window = Vector2I.Zero;   // 窗口按下时的左上角坐标（整数）
    private Vector2I drag_target_window_pos = Vector2I.Zero;   // 目标窗口位置（由鼠标计算得出）

    // Called when the node enters the scene tree for the first time.
    // override 表示重写父类的方法，_Ready 是 Godot 的生命周期方法之一，在节点准备好后调用。
    public override void _Ready()
    {
        GD.Print("开始运行");
        animated_sprite = GetNode<AnimatedSprite2D>("AnimatedSprite2D");
        if (animated_sprite?.SpriteFrames?.HasAnimation("kati") == true)
        {
            animated_sprite.Play("kati");
        }
        else
        {
            GD.Print("动画 'kati' 不存在");
        }

        MouseEntered += _on_mouse_entered;
        MouseExited += _on_mouse_exited;
        InputEvent += _on_area_input;
    }

    // Called every frame. 'delta' is the elapsed time since the previous frame.
    public override void _Process(double delta)
    {
    }

    public void _input(InputEvent @event)
    {
        if (@event is InputEventMouseButton mouseEvent && mouseEvent.Pressed)
        {
            Vector2 clickPosition = mouseEvent.Position;
            GD.Print($"鼠标点击位置: {clickPosition}");
        }
        if (@event is InputEventMouseMotion motionEvent && dragging)
        {
            // 将浮点相对移动转换为整数向量再加到窗口位置
            var rel = new Vector2I((int)motionEvent.Relative.X, (int)motionEvent.Relative.Y);
            GetWindow().Position += rel;
        }

        // 鼠标左键释放 → 停止拖拽
        if (@event is InputEventMouseButton buttonEvent &&
            buttonEvent.ButtonIndex == MouseButton.Left &&
            !buttonEvent.Pressed)
        {
            dragging = false;
        }

        // 右键按下 → 显示菜单
        if (@event is InputEventMouseButton rightEvent &&
            rightEvent.ButtonIndex == MouseButton.Right &&
            rightEvent.Pressed)
        {
            ShowContextMenu(rightEvent.GlobalPosition);
        }
    }

    public void _on_mouse_entered()
    {
        is_hovering = true;
        //GD.Print("鼠标进入");
    }

    public void _on_mouse_exited()
    {
        is_hovering = false;
        //GD.Print("鼠标离开");
    }

    public void _on_area_input(Node viewport, InputEvent @event, long shape_idx)
    {
        if (@event is InputEventMouseButton mouseEvent && mouseEvent.ButtonIndex == MouseButton.Left)
        {
            if (mouseEvent.Pressed)
            {
                dragging = true;
                drag_start_mouse = GetGlobalMousePosition();
                drag_start_window = GetWindow().Position;
                GD.Print("开始拖动"); 
            }
            else
            {
                dragging = false;
                GD.Print("停止拖动");
            }
        }
    }

    protected override void _BuildMenuItems(PopupMenu menu)
    {
        menu.AddItem("猫", 0);
        menu.AddItem("卡提", 1);
        menu.AddSeparator();
        menu.AddItem("退出", 3);
    }

    protected override void _OnMenuItemSelected(long id)
    {
        switch (id)
        {
            case 0:
                GD.Print("切换到猫");
                animated_sprite.Play("cat");
                break;
            case 1:
                GD.Print("切换到卡提");
                animated_sprite.Play("kati");
                break;
            case 3:
                GD.Print("退出宠物");
                GetTree().Quit();
                break;
            default:
                GD.PrintErr($"未知菜单 ID: {id}");
                break;
        }
    }
}