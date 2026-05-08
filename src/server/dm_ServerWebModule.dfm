object WebMain: TWebMain
  Actions = <
    item
      Default = True
      Name = 'DefaultHandler'
      PathInfo = '/'
      OnAction = WebModule1DefaultHandlerAction
    end>
  AfterDispatch = WebModule1DefaultHandlerAction
  Height = 230
  Width = 415
end
