class PositionManager
  def initialize(scope)
    @scope = scope
  end

  def next_position
    @scope.maximum(:position).to_i + 1
  end

  def swap(item1, item2)
    pos1 = item1.position
    pos2 = item2.position

    item1.class.transaction do
      temp_position = [pos1, pos2].max + 1000
      item1.update!(position: temp_position)
      item2.update!(position: pos1)
      item1.update!(position: pos2)
    end
  end

  def move_up(item)
    return false if item.position <= 0

    swap_with = @scope.find_by(position: item.position - 1)
    return false unless swap_with

    swap(item, swap_with)
    true
  end

  def move_down(item)
    swap_with = @scope.find_by(position: item.position + 1)
    return false unless swap_with

    swap(item, swap_with)
    true
  end

  def reorder(item, direction)
    case direction.to_s
    when "up" then move_up(item)
    when "down" then move_down(item)
    else false
    end
  end
end
