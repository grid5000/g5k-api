module UiHelper
  def relative_path_to(path)
    if controller.params[:action] == "visualization"
      File.join("..", path)
    else
      File.join(".", path)
    end
  end
end