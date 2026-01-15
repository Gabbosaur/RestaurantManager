import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'tutorial_overlay.dart';

/// Tutorial per la sezione Sala - Ordini
List<TutorialStep> getSalaOrdersTutorial(AppLanguage lang) {
  return switch (lang) {
    AppLanguage.chinese => [
      const TutorialStep(
        icon: Icons.receipt_long,
        title: '欢迎来到大厅！👋',
        description: '在这里你可以管理餐厅的所有订单。\n\n让我们一起看看怎么用。',
      ),
      const TutorialStep(
        icon: Icons.add_circle,
        title: '创建订单',
        description: '点击右下角的 + 按钮创建新订单。\n\n可以选择桌号或外卖。',
      ),
      const TutorialStep(
        icon: Icons.touch_app,
        title: '选择菜品',
        description: '点击菜品添加到订单。\n\n再点一次增加数量。\n\n长按可以添加备注或修改。',
      ),
      const TutorialStep(
        icon: Icons.local_drink,
        title: '饮料分开显示',
        description: '饮料会显示在上面，和菜品分开。\n\n这样更容易看到要先上什么！',
      ),
      const TutorialStep(
        icon: Icons.edit,
        title: '修改订单',
        description: '点击订单查看详情。\n\n可以修改、标记已送达或取消。',
      ),
      const TutorialStep(
        icon: Icons.sync,
        title: '自动同步',
        description: '订单会自动同步到厨房。\n\n创建订单后，厨房马上就能看到！🍳',
      ),
    ],
    AppLanguage.english => [
      const TutorialStep(
        icon: Icons.receipt_long,
        title: 'Welcome to the Hall! 👋',
        description: 'Here you can manage all restaurant orders.\n\nLet\'s see how it works.',
      ),
      const TutorialStep(
        icon: Icons.add_circle,
        title: 'Create an Order',
        description: 'Press the + button at the bottom right to create a new order.\n\nYou can choose a table or takeaway.',
      ),
      const TutorialStep(
        icon: Icons.touch_app,
        title: 'Select Dishes',
        description: 'Tap dishes to add them to the order.\n\nTap again to increase quantity.\n\nLong press to add notes or modify.',
      ),
      const TutorialStep(
        icon: Icons.local_drink,
        title: 'Beverages Separated',
        description: 'Beverages are shown at the top, separated from dishes.\n\nEasier to see what to serve first!',
      ),
      const TutorialStep(
        icon: Icons.edit,
        title: 'Edit an Order',
        description: 'Tap an order to see details.\n\nFrom there you can edit, mark as delivered, or cancel.',
      ),
      const TutorialStep(
        icon: Icons.sync,
        title: 'Auto Sync',
        description: 'Orders sync automatically with the kitchen.\n\nWhen you create an order, the kitchen sees it immediately! 🍳',
      ),
    ],
    AppLanguage.italian => [
      const TutorialStep(
        icon: Icons.receipt_long,
        title: 'Benvenuta nella Sala! 👋',
        description: 'Qui puoi gestire tutti gli ordini del ristorante.\n\nVediamo insieme come funziona.',
      ),
      const TutorialStep(
        icon: Icons.add_circle,
        title: 'Creare un Ordine',
        description: 'Premi il bottone + in basso a destra per creare un nuovo ordine.\n\nPuoi scegliere un tavolo o fare un ordine da asporto.',
      ),
      const TutorialStep(
        icon: Icons.touch_app,
        title: 'Selezionare i Piatti',
        description: 'Tocca i piatti per aggiungerli all\'ordine.\n\nTocca ancora per aumentare la quantità.\n\nTieni premuto per aggiungere note o modificare.',
      ),
      const TutorialStep(
        icon: Icons.local_drink,
        title: 'Bevande Separate',
        description: 'Le bevande vengono mostrate in alto, separate dai piatti.\n\nCosì è più facile vedere cosa servire subito!',
      ),
      const TutorialStep(
        icon: Icons.edit,
        title: 'Modificare un Ordine',
        description: 'Tocca un ordine per vedere i dettagli.\n\nDa lì puoi modificarlo, segnarlo come consegnato o annullarlo.',
      ),
      const TutorialStep(
        icon: Icons.sync,
        title: 'Sincronizzazione Automatica',
        description: 'Gli ordini si sincronizzano automaticamente con la cucina.\n\nQuando crei un ordine, papà lo vede subito! 🍳',
      ),
    ],
  };
}

/// Tutorial per la sezione Sala - Tavoli
List<TutorialStep> getSalaTablesTutorial(AppLanguage lang) {
  return switch (lang) {
    AppLanguage.chinese => [
      const TutorialStep(
        icon: Icons.table_restaurant,
        title: '桌位管理 🪑',
        description: '在这里可以看到所有桌子的状态。',
      ),
      const TutorialStep(
        icon: Icons.palette,
        title: '桌子颜色',
        description: '🟢 绿色 = 空闲\n🔴 红色 = 占用\n🟠 橙色 = 已预订\n\n占用的桌子会显示订单金额。',
      ),
      const TutorialStep(
        icon: Icons.touch_app,
        title: '点击操作',
        description: '点击空闲桌 → 创建订单\n点击占用桌 → 查看订单\n点击预订桌 → 选项',
      ),
      const TutorialStep(
        icon: Icons.event,
        title: '预订',
        description: '长按空闲桌可以预订。\n\n输入客人名字，桌子变成橙色。',
      ),
      const TutorialStep(
        icon: Icons.add,
        title: '添加桌子',
        description: '用 + 按钮添加新桌子。\n\n可以设置名称（T1, T2...）和座位数。',
      ),
    ],
    AppLanguage.english => [
      const TutorialStep(
        icon: Icons.table_restaurant,
        title: 'Table Management 🪑',
        description: 'Here you can see all tables and their status.',
      ),
      const TutorialStep(
        icon: Icons.palette,
        title: 'Table Colors',
        description: '🟢 Green = Available\n🔴 Red = Occupied\n🟠 Orange = Reserved\n\nOccupied tables show the order total.',
      ),
      const TutorialStep(
        icon: Icons.touch_app,
        title: 'Tap to Act',
        description: 'Tap available table → Create order\nTap occupied table → View order\nTap reserved table → Options',
      ),
      const TutorialStep(
        icon: Icons.event,
        title: 'Reservations',
        description: 'Long press on an available table to reserve it.\n\nEnter customer name and the table turns orange.',
      ),
      const TutorialStep(
        icon: Icons.add,
        title: 'Add Tables',
        description: 'Use the + button to add new tables.\n\nYou can set name (T1, T2...) and seats.',
      ),
    ],
    AppLanguage.italian => [
      const TutorialStep(
        icon: Icons.table_restaurant,
        title: 'Gestione Tavoli 🪑',
        description: 'Qui vedi tutti i tavoli del ristorante con il loro stato.',
      ),
      const TutorialStep(
        icon: Icons.palette,
        title: 'Colori dei Tavoli',
        description: '🟢 Verde = Libero\n🔴 Rosso = Occupato\n🟠 Arancione = Prenotato\n\nIl totale dell\'ordine appare sul tavolo occupato.',
      ),
      const TutorialStep(
        icon: Icons.touch_app,
        title: 'Tocca per Agire',
        description: 'Tocca un tavolo libero → Crea ordine\nTocca un tavolo occupato → Vedi ordine\nTocca un tavolo prenotato → Opzioni',
      ),
      const TutorialStep(
        icon: Icons.event,
        title: 'Prenotazioni',
        description: 'Tieni premuto su un tavolo libero per prenotarlo.\n\nInserisci il nome del cliente e il tavolo diventa arancione.',
      ),
      const TutorialStep(
        icon: Icons.add,
        title: 'Aggiungere Tavoli',
        description: 'Usa il bottone + per aggiungere nuovi tavoli.\n\nPuoi dare un nome (T1, T2...) e impostare i posti.',
      ),
    ],
  };
}

/// Tutorial per la sezione Menu
List<TutorialStep> getMenuTutorial(AppLanguage lang) {
  return switch (lang) {
    AppLanguage.chinese => [
      const TutorialStep(
        icon: Icons.restaurant_menu,
        title: '菜单管理 📋',
        description: '在这里可以管理餐厅的所有菜品。',
      ),
      const TutorialStep(
        icon: Icons.edit,
        title: '修改菜品',
        description: '点击任何菜品可以修改：\n\n• 名称和价格\n• 描述\n• 分类',
      ),
      const TutorialStep(
        icon: Icons.toggle_on,
        title: '启用/禁用菜品',
        description: '用开关可以暂时禁用某个菜品。\n\n比如某个食材用完了，可以先禁用。',
      ),
      const TutorialStep(
        icon: Icons.public,
        title: '实时同步',
        description: '所有修改都是即时生效的！\n\n客人看的电子菜单也会立即更新。📱',
      ),
      const TutorialStep(
        icon: Icons.add_circle,
        title: '添加新菜品',
        description: '用 + 按钮添加新菜品。\n\n记得设置正确的分类！',
      ),
    ],
    AppLanguage.english => [
      const TutorialStep(
        icon: Icons.restaurant_menu,
        title: 'Menu Management 📋',
        description: 'Here you can manage all restaurant dishes.',
      ),
      const TutorialStep(
        icon: Icons.edit,
        title: 'Edit Dishes',
        description: 'Tap any dish to edit:\n\n• Name and price\n• Description\n• Category',
      ),
      const TutorialStep(
        icon: Icons.toggle_on,
        title: 'Enable/Disable Dishes',
        description: 'Use the toggle to temporarily disable a dish.\n\nUseful when an ingredient runs out.',
      ),
      const TutorialStep(
        icon: Icons.public,
        title: 'Real-time Sync',
        description: 'All changes are instant!\n\nCustomers viewing the digital menu will see updates immediately. 📱',
      ),
      const TutorialStep(
        icon: Icons.add_circle,
        title: 'Add New Dishes',
        description: 'Use the + button to add new dishes.\n\nRemember to set the correct category!',
      ),
    ],
    AppLanguage.italian => [
      const TutorialStep(
        icon: Icons.restaurant_menu,
        title: 'Gestione Menu 📋',
        description: 'Qui puoi gestire tutti i piatti del ristorante.',
      ),
      const TutorialStep(
        icon: Icons.edit,
        title: 'Modificare i Piatti',
        description: 'Tocca un piatto per modificare:\n\n• Nome e prezzo\n• Descrizione\n• Categoria',
      ),
      const TutorialStep(
        icon: Icons.toggle_on,
        title: 'Abilitare/Disabilitare',
        description: 'Usa l\'interruttore per disabilitare temporaneamente un piatto.\n\nUtile quando finisce un ingrediente.',
      ),
      const TutorialStep(
        icon: Icons.public,
        title: 'Sincronizzazione Istantanea',
        description: 'Tutte le modifiche sono immediate!\n\nI clienti che guardano il menu digitale vedranno subito gli aggiornamenti. 📱',
      ),
      const TutorialStep(
        icon: Icons.add_circle,
        title: 'Aggiungere Nuovi Piatti',
        description: 'Usa il bottone + per aggiungere nuovi piatti.\n\nRicorda di impostare la categoria corretta!',
      ),
    ],
  };
}

/// Tutorial per la Cucina
List<TutorialStep> getKitchenTutorial(AppLanguage lang) {
  return switch (lang) {
    AppLanguage.chinese => [
      const TutorialStep(
        icon: Icons.restaurant,
        title: '欢迎来到厨房！👨‍🍳',
        description: '在这里可以看到所有要做的订单。',
      ),
      const TutorialStep(
        icon: Icons.view_column,
        title: '订单分栏显示',
        description: '订单按状态分类：\n\n⏳ 待准备\n✅ 已完成\n🍽️ 已送达',
      ),
      const TutorialStep(
        icon: Icons.local_drink,
        title: '饮料在下面',
        description: '饮料显示在下面，字小一点。\n\n专心做菜就好！🍜',
      ),
      const TutorialStep(
        icon: Icons.check_circle,
        title: '标记完成',
        description: '订单做好后点击 ✓。\n\n订单会移到"已完成"栏。\n\n然后妈妈会标记送达。',
      ),
      const TutorialStep(
        icon: Icons.edit_note,
        title: '修改标记',
        description: '如果订单被修改了，\n新加的菜会用绿色标出来。',
      ),
      const TutorialStep(
        icon: Icons.notifications_active,
        title: '实时更新',
        description: '新订单会自动出现。\n\n不用刷新！🔄',
      ),
    ],
    AppLanguage.english => [
      const TutorialStep(
        icon: Icons.restaurant,
        title: 'Welcome to the Kitchen! 👨‍🍳',
        description: 'Here you can see all orders to prepare.',
      ),
      const TutorialStep(
        icon: Icons.view_column,
        title: 'Orders in Columns',
        description: 'Orders are organized by status:\n\n⏳ To prepare\n✅ Ready\n🍽️ Delivered',
      ),
      const TutorialStep(
        icon: Icons.local_drink,
        title: 'Beverages at Bottom',
        description: 'Beverages are shown at the bottom, smaller.\n\nFocus on the dishes! 🍜',
      ),
      const TutorialStep(
        icon: Icons.check_circle,
        title: 'Mark as Ready',
        description: 'Tap ✓ when the order is ready.\n\nThe order moves to "Ready" column.\n\nThen the hall marks it as delivered.',
      ),
      const TutorialStep(
        icon: Icons.edit_note,
        title: 'Changes Highlighted',
        description: 'If an order is modified,\nnew items are highlighted in green.',
      ),
      const TutorialStep(
        icon: Icons.notifications_active,
        title: 'Real-time Updates',
        description: 'New orders appear automatically.\n\nNo need to refresh! 🔄',
      ),
    ],
    AppLanguage.italian => [
      const TutorialStep(
        icon: Icons.restaurant,
        title: 'Benvenuto in Cucina! 👨‍🍳',
        description: 'Qui vedi tutti gli ordini da preparare.',
      ),
      const TutorialStep(
        icon: Icons.view_column,
        title: 'Ordini in Colonne',
        description: 'Gli ordini sono organizzati per stato:\n\n⏳ Da preparare\n✅ Pronti\n🍽️ Consegnati',
      ),
      const TutorialStep(
        icon: Icons.local_drink,
        title: 'Bevande in Basso',
        description: 'Le bevande sono in basso, più piccole.\n\nConcentrati sui piatti! 🍜',
      ),
      const TutorialStep(
        icon: Icons.check_circle,
        title: 'Segnare come Pronto',
        description: 'Tocca ✓ quando l\'ordine è pronto.\n\nL\'ordine si sposta nella colonna "Pronti".\n\nPoi la sala lo segna come consegnato.',
      ),
      const TutorialStep(
        icon: Icons.edit_note,
        title: 'Modifiche Evidenziate',
        description: 'Se un ordine viene modificato,\nle aggiunte sono evidenziate in verde.',
      ),
      const TutorialStep(
        icon: Icons.notifications_active,
        title: 'Aggiornamenti in Tempo Reale',
        description: 'I nuovi ordini appaiono automaticamente.\n\nNon serve aggiornare! 🔄',
      ),
    ],
  };
}
