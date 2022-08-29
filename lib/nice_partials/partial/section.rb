class NicePartials::Partial::Section < NicePartials::Partial::Content
  def content_for(content = nil)
    self unless concat(content)
  end
end
