using Godot;
using System;

/// <summary>
/// 抽象菜单基类，继承自 Area2D，提供右键弹出菜单的通用逻辑。
/// 子类必须重写 _BuildMenuItems 和 _OnMenuItemSelected。
/// </summary>
public abstract partial class Menu : Area2D
{
    private PopupMenu _menu;

    /// <summary>
    /// 在指定位置显示上下文菜单。
    /// </summary>
    /// <param name="globalPos">屏幕全局坐标</param>
    public void ShowContextMenu(Vector2 globalPos)
    {
        // 确保节点在场景树中
        if (!IsInsideTree())
        {
            GD.PrintErr("警告：节点不在场景树中，无法弹出菜单");
            return;
        }

        // 清理旧菜单
        if (_menu != null && IsInstanceValid(_menu))
        {
            _menu.QueueFree();
            _menu = null;
        }

        // 创建新菜单
        _menu = new PopupMenu();
        GetTree().Root.AddChild(_menu);
        _menu.Position = (Vector2I)globalPos; // 转换为整数坐标

        // 让子类构建菜单项
        _BuildMenuItems(_menu);

        // 连接信号
        _menu.IdPressed += _OnMenuItemSelected;
        _menu.PopupHide += _OnMenuHidden;

        // 弹出菜单
        _menu.Popup();
    }

    /// <summary>
    /// 子类必须重写此方法，用于向菜单中添加项。
    /// </summary>
    /// <param name="menu">待构建的 PopupMenu 实例</param>
    protected abstract void _BuildMenuItems(PopupMenu menu);

    /// <summary>
    /// 子类必须重写此方法，处理菜单项点击事件。
    /// </summary>
    /// <param name="id">菜单项 ID</param>
    protected abstract void _OnMenuItemSelected(long id);

    // 菜单隐藏时的清理
    private void _OnMenuHidden()
    {
        if (_menu != null && IsInstanceValid(_menu))
        {
            _menu.QueueFree();
            _menu = null;
        }
    }
}