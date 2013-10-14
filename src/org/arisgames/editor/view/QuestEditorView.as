package org.arisgames.editor.view
{
  import flash.events.Event;
  import flash.events.MouseEvent;

  import mx.containers.Panel;
  import mx.controls.Alert;
  import mx.controls.Button;
  import mx.controls.DataGrid;
  import mx.events.DataGridEvent;
  import mx.events.DynamicEvent;
  import mx.events.ListEvent;
  import mx.events.FlexEvent;
  import mx.managers.PopUpManager;
  import mx.rpc.Responder;
  import mx.collections.ArrayCollection;

  import org.arisgames.editor.data.arisserver.Quest;
  import org.arisgames.editor.models.GameModel;
  import org.arisgames.editor.services.AppServices;
  import org.arisgames.editor.util.AppConstants;
  import org.arisgames.editor.util.AppDynamicEventManager;

  public class QuestEditorView extends Panel
  {
    [Bindable] public var quest:ArrayCollection;

    [Bindable] public var dg:DataGrid;
    [Bindable] public var addQuestButton:Button;
    [Bindable] public var closeButton:Button;

    public function QuestEditorView()
    {
      super();
      this.addEventListener(FlexEvent.CREATION_COMPLETE, handleInit);
    }

    private function handleInit(event:FlexEvent):void
    {
      quest = new ArrayCollection();

      closeButton.addEventListener(MouseEvent.CLICK, handleCloseButton);
      addQuestButton.addEventListener(MouseEvent.CLICK, handleAddQuestButton);

      this.reloadTheQuests();
    }

    private function reloadTheQuests():void
    {
      AppServices.getInstance().getQuestsByGameId(GameModel.getInstance().game.gameId, new Responder(handleLoadQuests, handleFault));
    }
  
    private function handleLoadQuests(obj:Object):void
    {
      if(obj.result.returnCode != 0) { Alert.show("Error Was: " + obj.result.returnCodeDescription, "Error While Loading Quests"); return; }

      quest.removeAll();
      for(var i:Number = 0; i < obj.result.data.list.length; i++)
      {
        var q:Quest = new Quest();
        q.questId                = obj.result.data.list.getItemAt(i).quest_id;
        q.title                  = obj.result.data.list.getItemAt(i).name;
        q.activeText             = obj.result.data.list.getItemAt(i).description;
        q.completeText           = obj.result.data.list.getItemAt(i).text_when_complete;
        q.activeMediaId          = obj.result.data.list.getItemAt(i).active_media_id;
        q.completeMediaId        = obj.result.data.list.getItemAt(i).complete_media_id;
        q.activeIconMediaId      = obj.result.data.list.getItemAt(i).active_icon_media_id;
        q.completeIconMediaId    = obj.result.data.list.getItemAt(i).complete_icon_media_id;
        q.fullScreenNotification = obj.result.data.list.getItemAt(i).full_screen_notify;
        q.index = i;
        if(q.index != obj.result.data.list.getItemAt(i).sort_index)
          AppServices.getInstance().saveQuest(GameModel.getInstance().game.gameId, q, new Responder(handleUpdateQuestSave, handleFault));

        quest.addItem(q);
      }
      quest.refresh();
    }

    public function handleQuestSortUp(evt:Event):void
    {
      if(dg.selectedIndex > 0 && dg.selectedIndex < quest.length)
      {
        var q1:Quest = (quest.getItemAt(dg.selectedIndex)   as Quest);
        var q2:Quest = (quest.getItemAt(dg.selectedIndex-1) as Quest);
        AppServices.getInstance().switchQuestOrder(GameModel.getInstance().game.gameId, q1.questId, q2.questId, new Responder(handleSwitchedSortPosUp, handleFault));
      }
    }

    private function handleSwitchedSortPosUp(obj:Object):void
    {
      if(obj.result.returnCode != 0) { Alert.show("QuestsEditorView: Error Was: " + obj.result.returnCodeDescription, "Error While Saving Quest"); return; }

      var sel:Number = dg.selectedIndex;
      quest.getItemAt(sel).index = sel-1;
      quest.getItemAt(sel-1).index = sel;
      quest.addItemAt(quest.removeItemAt(sel), sel-1);
      quest.refresh();
    }

    public function handleQuestSortDown(evt:Event):void
    {
      if(dg.selectedIndex >= 0 && dg.selectedIndex < quest.length-1)
      {
        var q1:Quest = (quest.getItemAt(dg.selectedIndex)   as Quest);
        var q2:Quest = (quest.getItemAt(dg.selectedIndex+1) as Quest);
        AppServices.getInstance().switchQuestOrder(GameModel.getInstance().game.gameId, q1.questId, q2.questId, new Responder(handleSwitchedSortPosDown, handleFault));
      }
    }
 
    private function handleSwitchedSortPosDown(obj:Object):void
    {
      if(obj.result.returnCode != 0) { Alert.show("QuestsEditorView: Error Was: " + obj.result.returnCodeDescription, "Error While Saving Quest"); return; }

      var sel:Number = dg.selectedIndex;
      quest.getItemAt(sel).index = sel+1;
      quest.getItemAt(sel+1).index = sel;
      quest.addItemAt(quest.removeItemAt(sel), sel+1);
      quest.refresh();
    }

    public function handleDeleteButtonClick(evt:MouseEvent):void
    {
      AppServices.getInstance().deleteQuest(GameModel.getInstance().game.gameId, (quest.getItemAt(dg.selectedIndex) as Quest), new Responder(handleDeleteQuest, handleFault));
    }

    private function handleDeleteQuest(obj:Object):void
    {
      if(obj.result.returnCode != 0) { Alert.show("Error Was: " + obj.result.returnCodeDescription, "Error While Deleting Quest"); return; }

      var sel:Number = dg.selectedIndex;
      quest.removeItemAt(sel);
      for(var x:Number = sel; x < quest.length; x++)
      {
        var q:Quest = quest.getItemAt(x) as Quest;
        q.index = x;
        AppServices.getInstance().saveQuest(GameModel.getInstance().game.gameId, q, new Responder(handleUpdateQuestSave, handleFault));
      }
      quest.refresh();
    }

    private function handleUpdateQuestSave(obj:Object):void
    {
      if(obj.result.returnCode != 0) Alert.show("Error Was: " + obj.result.returnCodeDescription, "Error While Updating Quest");
    }

    private function handleAddQuestButton(evt:MouseEvent):void
    {
      var q:Quest = new Quest();
      q.index = quest.length;
      AppServices.getInstance().saveQuest(GameModel.getInstance().game.gameId, q, new Responder(handleAddQuestSave, handleFault));
    }

    private function handleAddQuestSave(obj:Object):void
    {
      if(obj.result.returnCode != 0) { Alert.show("Error Was: " + obj.result.returnCodeDescription, "Error While Adding / Save Quest"); return; }

      var qid:Number = obj.result.data;

      var q:Quest = new Quest();
      q.questId = qid;
      q.index = quest.length;
      quest.addItem(q);
    }

    private function handleCloseButton(evt:MouseEvent):void
    {
      var de:DynamicEvent = new DynamicEvent(AppConstants.DYNAMICEVENT_CLOSEQUESTSEDITOR);
      AppDynamicEventManager.getInstance().dispatchEvent(de);
    }

    public function handleFault(obj:Object):void
    {
      Alert.show("Error occurred: " + obj.message, "Problems In Quests Editor");
    }
  }
}