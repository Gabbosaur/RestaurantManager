import 'package:flutter/material.dart';

enum AppLanguage { italian, english, chinese }

class AppLocalizations {
  final AppLanguage language;

  AppLocalizations(this.language);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(AppLanguage.italian);
  }

  String get languageName => switch (language) {
        AppLanguage.italian => 'Italiano',
        AppLanguage.english => 'English',
        AppLanguage.chinese => '中文',
      };

  // Navigation
  String get orders => switch (language) {
        AppLanguage.italian => 'Ordini',
        AppLanguage.english => 'Orders',
        AppLanguage.chinese => '订单',
      };

  String get tables => switch (language) {
        AppLanguage.italian => 'Tavoli',
        AppLanguage.english => 'Tables',
        AppLanguage.chinese => '餐桌',
      };

  String get menu => switch (language) {
        AppLanguage.italian => 'Menu',
        AppLanguage.english => 'Menu',
        AppLanguage.chinese => '菜单',
      };

  String get inventory => switch (language) {
        AppLanguage.italian => 'Ingredienti',
        AppLanguage.english => 'Ingredients',
        AppLanguage.chinese => '食材',
      };

  String get ingredientsInfo => switch (language) {
        AppLanguage.italian => 'Disattiva gli ingredienti esauriti. I piatti collegati non saranno ordinabili.',
        AppLanguage.english => 'Disable unavailable ingredients. Related dishes won\'t be orderable.',
        AppLanguage.chinese => '禁用缺货食材。相关菜品将无法点单。',
      };

  String get unavailableIngredients => switch (language) {
        AppLanguage.italian => 'Non disponibili',
        AppLanguage.english => 'Unavailable',
        AppLanguage.chinese => '缺货',
      };

  String get availableIngredients => switch (language) {
        AppLanguage.italian => 'Disponibili',
        AppLanguage.english => 'Available',
        AppLanguage.chinese => '有货',
      };

  String get resetAll => switch (language) {
        AppLanguage.italian => 'Ripristina tutti',
        AppLanguage.english => 'Reset all',
        AppLanguage.chinese => '全部重置',
      };

  String get coverCharge => switch (language) {
        AppLanguage.italian => 'Coperto',
        AppLanguage.english => 'Cover',
        AppLanguage.chinese => '餐位费',
      };

  // Orders
  String get newOrder => switch (language) {
        AppLanguage.italian => 'Nuovo Ordine',
        AppLanguage.english => 'New Order',
        AppLanguage.chinese => '新订单',
      };

  String get table => switch (language) {
        AppLanguage.italian => 'Tavolo',
        AppLanguage.english => 'Table',
        AppLanguage.chinese => '餐桌',
      };

  String get takeaway => switch (language) {
        AppLanguage.italian => 'Asporto',
        AppLanguage.english => 'Takeaway',
        AppLanguage.chinese => '外卖',
      };

  String get people => switch (language) {
        AppLanguage.italian => 'Persone',
        AppLanguage.english => 'People',
        AppLanguage.chinese => '人数',
      };

  String get total => switch (language) {
        AppLanguage.italian => 'Totale',
        AppLanguage.english => 'Total',
        AppLanguage.chinese => '总计',
      };

  String get notes => switch (language) {
        AppLanguage.italian => 'Note',
        AppLanguage.english => 'Notes',
        AppLanguage.chinese => '备注',
      };

  String get createOrder => switch (language) {
        AppLanguage.italian => 'Crea Ordine',
        AppLanguage.english => 'Create Order',
        AppLanguage.chinese => '创建订单',
      };

  String get activeOrders => switch (language) {
        AppLanguage.italian => 'Ordini Attivi',
        AppLanguage.english => 'Active Orders',
        AppLanguage.chinese => '进行中',
      };

  String get completedToday => switch (language) {
        AppLanguage.italian => 'Completati Oggi',
        AppLanguage.english => 'Completed Today',
        AppLanguage.chinese => '今日完成',
      };

  String get noOrders => switch (language) {
        AppLanguage.italian => 'Nessun ordine',
        AppLanguage.english => 'No orders',
        AppLanguage.chinese => '暂无订单',
      };

  // Order status
  String get pending => switch (language) {
        AppLanguage.italian => 'In attesa',
        AppLanguage.english => 'Pending',
        AppLanguage.chinese => '待处理',
      };

  String get preparing => switch (language) {
        AppLanguage.italian => 'In preparazione',
        AppLanguage.english => 'Preparing',
        AppLanguage.chinese => '准备中',
      };

  String get ready => switch (language) {
        AppLanguage.italian => 'Pronto',
        AppLanguage.english => 'Ready',
        AppLanguage.chinese => '已完成',
      };

  String get served => switch (language) {
        AppLanguage.italian => 'Completato',
        AppLanguage.english => 'Completed',
        AppLanguage.chinese => '已完成',
      };

  String get paid => switch (language) {
        AppLanguage.italian => 'Pagato',
        AppLanguage.english => 'Paid',
        AppLanguage.chinese => '已付款',
      };

  String get cancelled => switch (language) {
        AppLanguage.italian => 'Annullato',
        AppLanguage.english => 'Cancelled',
        AppLanguage.chinese => '已取消',
      };

  String get markAsPaid => switch (language) {
        AppLanguage.italian => 'Segna Pagato',
        AppLanguage.english => 'Mark as Paid',
        AppLanguage.chinese => '标记已付款',
      };

  // Actions
  String get prepare => switch (language) {
        AppLanguage.italian => 'Prepara',
        AppLanguage.english => 'Prepare',
        AppLanguage.chinese => '开始',
      };

  String get done => switch (language) {
        AppLanguage.italian => 'Fatto',
        AppLanguage.english => 'Done',
        AppLanguage.chinese => '完成',
      };

  String get save => switch (language) {
        AppLanguage.italian => 'Salva',
        AppLanguage.english => 'Save',
        AppLanguage.chinese => '保存',
      };

  String get cancel => switch (language) {
        AppLanguage.italian => 'Annulla',
        AppLanguage.english => 'Cancel',
        AppLanguage.chinese => '取消',
      };

  String get delete => switch (language) {
        AppLanguage.italian => 'Elimina',
        AppLanguage.english => 'Delete',
        AppLanguage.chinese => '删除',
      };

  String get add => switch (language) {
        AppLanguage.italian => 'Aggiungi',
        AppLanguage.english => 'Add',
        AppLanguage.chinese => '添加',
      };

  String get others => switch (language) {
        AppLanguage.italian => 'altri',
        AppLanguage.english => 'others',
        AppLanguage.chinese => '其他',
      };

  String get edit => switch (language) {
        AppLanguage.italian => 'Modifica',
        AppLanguage.english => 'Edit',
        AppLanguage.chinese => '编辑',
      };

  String get retry => switch (language) {
        AppLanguage.italian => 'Riprova',
        AppLanguage.english => 'Retry',
        AppLanguage.chinese => '重试',
      };

  // Tables
  String get available => switch (language) {
        AppLanguage.italian => 'Libero',
        AppLanguage.english => 'Available',
        AppLanguage.chinese => '空闲',
      };

  String get occupied => switch (language) {
        AppLanguage.italian => 'Occupato',
        AppLanguage.english => 'Occupied',
        AppLanguage.chinese => '使用中',
      };

  String get reserved => switch (language) {
        AppLanguage.italian => 'Prenotato',
        AppLanguage.english => 'Reserved',
        AppLanguage.chinese => '已预订',
      };

  String get cleaning => switch (language) {
        AppLanguage.italian => 'Pulizia',
        AppLanguage.english => 'Cleaning',
        AppLanguage.chinese => '清洁中',
      };

  String get seats => switch (language) {
        AppLanguage.italian => 'posti',
        AppLanguage.english => 'seats',
        AppLanguage.chinese => '座位',
      };

  String get noTables => switch (language) {
        AppLanguage.italian => 'Nessun tavolo',
        AppLanguage.english => 'No tables',
        AppLanguage.chinese => '暂无餐桌',
      };

  String get addTable => switch (language) {
        AppLanguage.italian => 'Aggiungi Tavolo',
        AppLanguage.english => 'Add Table',
        AppLanguage.chinese => '添加餐桌',
      };

  String get dragToPosition => switch (language) {
        AppLanguage.italian => 'Trascina i tavoli per posizionarli',
        AppLanguage.english => 'Drag tables to position them',
        AppLanguage.chinese => '拖动餐桌调整位置',
      };

  String get markAvailable => switch (language) {
        AppLanguage.italian => 'Libera',
        AppLanguage.english => 'Free',
        AppLanguage.chinese => '空闲',
      };

  String get markOccupied => switch (language) {
        AppLanguage.italian => 'Occupa',
        AppLanguage.english => 'Occupy',
        AppLanguage.chinese => '使用',
      };

  String get reserve => switch (language) {
        AppLanguage.italian => 'Prenota',
        AppLanguage.english => 'Reserve',
        AppLanguage.chinese => '预订',
      };

  String get needsCleaning => switch (language) {
        AppLanguage.italian => 'Da pulire',
        AppLanguage.english => 'Needs cleaning',
        AppLanguage.chinese => '需清洁',
      };

  String get reservation => switch (language) {
        AppLanguage.italian => 'Prenotazione',
        AppLanguage.english => 'Reservation',
        AppLanguage.chinese => '预订',
      };

  String get customerName => switch (language) {
        AppLanguage.italian => 'Nome cliente',
        AppLanguage.english => 'Customer name',
        AppLanguage.chinese => '客户姓名',
      };

  // Menu
  String get emptyMenu => switch (language) {
        AppLanguage.italian => 'Menu vuoto',
        AppLanguage.english => 'Empty menu',
        AppLanguage.chinese => '菜单为空',
      };

  String get newDish => switch (language) {
        AppLanguage.italian => 'Nuovo Piatto',
        AppLanguage.english => 'New Dish',
        AppLanguage.chinese => '新菜品',
      };

  String get editDish => switch (language) {
        AppLanguage.italian => 'Modifica Piatto',
        AppLanguage.english => 'Edit Dish',
        AppLanguage.chinese => '编辑菜品',
      };

  String get name => switch (language) {
        AppLanguage.italian => 'Nome',
        AppLanguage.english => 'Name',
        AppLanguage.chinese => '名称',
      };

  String get description => switch (language) {
        AppLanguage.italian => 'Descrizione',
        AppLanguage.english => 'Description',
        AppLanguage.chinese => '描述',
      };

  String get price => switch (language) {
        AppLanguage.italian => 'Prezzo',
        AppLanguage.english => 'Price',
        AppLanguage.chinese => '价格',
      };

  String get category => switch (language) {
        AppLanguage.italian => 'Categoria',
        AppLanguage.english => 'Category',
        AppLanguage.chinese => '分类',
      };

  // Inventory
  String get emptyInventory => switch (language) {
        AppLanguage.italian => 'Magazzino vuoto',
        AppLanguage.english => 'Empty inventory',
        AppLanguage.chinese => '库存为空',
      };

  String get lowStock => switch (language) {
        AppLanguage.italian => 'Scorte Basse',
        AppLanguage.english => 'Low Stock',
        AppLanguage.chinese => '库存不足',
      };

  String get inStock => switch (language) {
        AppLanguage.italian => 'In Magazzino',
        AppLanguage.english => 'In Stock',
        AppLanguage.chinese => '有库存',
      };

  String get newProduct => switch (language) {
        AppLanguage.italian => 'Nuovo Prodotto',
        AppLanguage.english => 'New Product',
        AppLanguage.chinese => '新产品',
      };

  String get editProduct => switch (language) {
        AppLanguage.italian => 'Modifica Prodotto',
        AppLanguage.english => 'Edit Product',
        AppLanguage.chinese => '编辑产品',
      };

  String get quantity => switch (language) {
        AppLanguage.italian => 'Quantità',
        AppLanguage.english => 'Quantity',
        AppLanguage.chinese => '数量',
      };

  String get unit => switch (language) {
        AppLanguage.italian => 'Unità',
        AppLanguage.english => 'Unit',
        AppLanguage.chinese => '单位',
      };

  String get minStock => switch (language) {
        AppLanguage.italian => 'Scorta Minima',
        AppLanguage.english => 'Min Stock',
        AppLanguage.chinese => '最低库存',
      };

  String get supplier => switch (language) {
        AppLanguage.italian => 'Fornitore',
        AppLanguage.english => 'Supplier',
        AppLanguage.chinese => '供应商',
      };

  String get noSupplier => switch (language) {
        AppLanguage.italian => 'Nessun fornitore',
        AppLanguage.english => 'No supplier',
        AppLanguage.chinese => '无供应商',
      };

  String get restock => switch (language) {
        AppLanguage.italian => 'Rifornisci',
        AppLanguage.english => 'Restock',
        AppLanguage.chinese => '补货',
      };

  String get addQuantity => switch (language) {
        AppLanguage.italian => 'Aggiungi quantità',
        AppLanguage.english => 'Add quantity',
        AppLanguage.chinese => '添加数量',
      };

  String itemsLowStock(int count) => switch (language) {
        AppLanguage.italian => '$count prodotti in esaurimento',
        AppLanguage.english => '$count items low on stock',
        AppLanguage.chinese => '$count 件商品库存不足',
      };

  // Settings
  String get settings => switch (language) {
        AppLanguage.italian => 'Impostazioni',
        AppLanguage.english => 'Settings',
        AppLanguage.chinese => '设置',
      };

  String get languageLabel => switch (language) {
        AppLanguage.italian => 'Lingua',
        AppLanguage.english => 'Language',
        AppLanguage.chinese => '语言',
      };

  String get theme => switch (language) {
        AppLanguage.italian => 'Tema',
        AppLanguage.english => 'Theme',
        AppLanguage.chinese => '主题',
      };

  String get lightTheme => switch (language) {
        AppLanguage.italian => 'Chiaro',
        AppLanguage.english => 'Light',
        AppLanguage.chinese => '浅色',
      };

  String get darkTheme => switch (language) {
        AppLanguage.italian => 'Scuro',
        AppLanguage.english => 'Dark',
        AppLanguage.chinese => '深色',
      };

  String get close => switch (language) {
        AppLanguage.italian => 'Chiudi',
        AppLanguage.english => 'Close',
        AppLanguage.chinese => '关闭',
      };

  // Tutorial
  String get resetTutorial => switch (language) {
        AppLanguage.italian => 'Rivedi Tutorial',
        AppLanguage.english => 'Reset Tutorial',
        AppLanguage.chinese => '重置教程',
      };

  String get tutorialReset => switch (language) {
        AppLanguage.italian => 'Tutorial resettato! Verrà mostrato al prossimo accesso.',
        AppLanguage.english => 'Tutorial reset! It will show on next access.',
        AppLanguage.chinese => '教程已重置！下次访问时将显示。',
      };

  // Auth
  String get email => switch (language) {
        AppLanguage.italian => 'Email',
        AppLanguage.english => 'Email',
        AppLanguage.chinese => '邮箱',
      };

  String get password => switch (language) {
        AppLanguage.italian => 'Password',
        AppLanguage.english => 'Password',
        AppLanguage.chinese => '密码',
      };

  String get signIn => switch (language) {
        AppLanguage.italian => 'Accedi',
        AppLanguage.english => 'Sign In',
        AppLanguage.chinese => '登录',
      };

  String get signUp => switch (language) {
        AppLanguage.italian => 'Registrati',
        AppLanguage.english => 'Sign Up',
        AppLanguage.chinese => '注册',
      };

  String get noAccount => switch (language) {
        AppLanguage.italian => 'Non hai un account? Registrati',
        AppLanguage.english => "Don't have an account? Sign Up",
        AppLanguage.chinese => '没有账号？注册',
      };

  String get hasAccount => switch (language) {
        AppLanguage.italian => 'Hai già un account? Accedi',
        AppLanguage.english => 'Already have an account? Sign In',
        AppLanguage.chinese => '已有账号？登录',
      };

  String get selectAtLeastOne => switch (language) {
        AppLanguage.italian => 'Seleziona almeno un piatto',
        AppLanguage.english => 'Select at least one item',
        AppLanguage.chinese => '请至少选择一道菜',
      };

  String get enterTableNumber => switch (language) {
        AppLanguage.italian => 'Inserisci il numero del tavolo',
        AppLanguage.english => 'Enter table number',
        AppLanguage.chinese => '请输入桌号',
      };

  // Shapes
  String get square => switch (language) {
        AppLanguage.italian => 'Quadrato',
        AppLanguage.english => 'Square',
        AppLanguage.chinese => '方形',
      };

  String get round => switch (language) {
        AppLanguage.italian => 'Rotondo',
        AppLanguage.english => 'Round',
        AppLanguage.chinese => '圆形',
      };

  String get rectangle => switch (language) {
        AppLanguage.italian => 'Rettangolo',
        AppLanguage.english => 'Rectangle',
        AppLanguage.chinese => '长方形',
      };

  // Kitchen
  String get kitchen => switch (language) {
        AppLanguage.italian => 'Cucina',
        AppLanguage.english => 'Kitchen',
        AppLanguage.chinese => '厨房',
      };

  String get newOrders => switch (language) {
        AppLanguage.italian => 'Nuovi',
        AppLanguage.english => 'New',
        AppLanguage.chinese => '新订单',
      };

  String get inPreparation => switch (language) {
        AppLanguage.italian => 'In Preparazione',
        AppLanguage.english => 'In Preparation',
        AppLanguage.chinese => '准备中',
      };

  String get readyToServe => switch (language) {
        AppLanguage.italian => 'Pronti',
        AppLanguage.english => 'Ready',
        AppLanguage.chinese => '已完成',
      };

  String get startPreparing => switch (language) {
        AppLanguage.italian => 'Inizia',
        AppLanguage.english => 'Start',
        AppLanguage.chinese => '开始',
      };

  String get markReady => switch (language) {
        AppLanguage.italian => 'Pronto!',
        AppLanguage.english => 'Ready!',
        AppLanguage.chinese => '完成!',
      };

  String get noNewOrders => switch (language) {
        AppLanguage.italian => 'Nessun nuovo ordine',
        AppLanguage.english => 'No new orders',
        AppLanguage.chinese => '暂无新订单',
      };

  String get noPreparing => switch (language) {
        AppLanguage.italian => 'Nessun ordine in preparazione',
        AppLanguage.english => 'No orders in preparation',
        AppLanguage.chinese => '暂无准备中的订单',
      };

  String get noReady => switch (language) {
        AppLanguage.italian => 'Nessun ordine pronto',
        AppLanguage.english => 'No orders ready',
        AppLanguage.chinese => '暂无已完成订单',
      };

  String minutesAgo(int minutes) => switch (language) {
        AppLanguage.italian => '$minutes min fa',
        AppLanguage.english => '$minutes min ago',
        AppLanguage.chinese => '$minutes 分钟前',
      };

  String get justNow => switch (language) {
        AppLanguage.italian => 'Adesso',
        AppLanguage.english => 'Just now',
        AppLanguage.chinese => '刚刚',
      };

  String get exit => switch (language) {
        AppLanguage.italian => 'Esci',
        AppLanguage.english => 'Exit',
        AppLanguage.chinese => '退出',
      };

  String get selectRole => switch (language) {
        AppLanguage.italian => 'Seleziona Ruolo',
        AppLanguage.english => 'Select Role',
        AppLanguage.chinese => '选择角色',
      };

  String get diningRoom => switch (language) {
        AppLanguage.italian => 'Sala',
        AppLanguage.english => 'Dining Room',
        AppLanguage.chinese => '餐厅',
      };

  String get diningRoomDesc => switch (language) {
        AppLanguage.italian => 'Gestisci ordini, tavoli e menu',
        AppLanguage.english => 'Manage orders, tables and menu',
        AppLanguage.chinese => '管理订单、餐桌和菜单',
      };

  String get kitchenDesc => switch (language) {
        AppLanguage.italian => 'Visualizza e prepara gli ordini',
        AppLanguage.english => 'View and prepare orders',
        AppLanguage.chinese => '查看和准备订单',
      };

  // Order slip
  String get drinks => switch (language) {
        AppLanguage.italian => 'Bevande',
        AppLanguage.english => 'Drinks',
        AppLanguage.chinese => '饮料',
      };

  String get unsavedChanges => switch (language) {
        AppLanguage.italian => 'Modifiche non salvate',
        AppLanguage.english => 'Unsaved changes',
        AppLanguage.chinese => '未保存的更改',
      };

  String get discardChangesQuestion => switch (language) {
        AppLanguage.italian => 'Vuoi salvare le modifiche prima di uscire?',
        AppLanguage.english => 'Do you want to save changes before leaving?',
        AppLanguage.chinese => '离开前要保存更改吗？',
      };

  String get discard => switch (language) {
        AppLanguage.italian => 'Scarta',
        AppLanguage.english => 'Discard',
        AppLanguage.chinese => '放弃',
      };

  String get openOrder => switch (language) {
        AppLanguage.italian => 'Apri Comanda',
        AppLanguage.english => 'Open Order',
        AppLanguage.chinese => '打开订单',
      };

  String get selectTable => switch (language) {
        AppLanguage.italian => 'Seleziona un tavolo',
        AppLanguage.english => 'Select a table',
        AppLanguage.chinese => '选择餐桌',
      };

  String orderedToday(int count) => switch (language) {
        AppLanguage.italian => 'Ordinato $count volte oggi',
        AppLanguage.english => 'Ordered $count times today',
        AppLanguage.chinese => '今日已点 $count 次',
      };

  String get highUsageWarning => switch (language) {
        AppLanguage.italian => 'Molto richiesto!',
        AppLanguage.english => 'High demand!',
        AppLanguage.chinese => '需求量大！',
      };

  // Conflict handling
  String get ingredientNowUnavailable => switch (language) {
        AppLanguage.italian => 'Non più disponibile',
        AppLanguage.english => 'No longer available',
        AppLanguage.chinese => '已无货',
      };

  String get someItemsUnavailable => switch (language) {
        AppLanguage.italian => 'Alcuni piatti non sono più disponibili',
        AppLanguage.english => 'Some items are no longer available',
        AppLanguage.chinese => '部分菜品已无货',
      };

  String get removeUnavailable => switch (language) {
        AppLanguage.italian => 'Rimuovi',
        AppLanguage.english => 'Remove',
        AppLanguage.chinese => '移除',
      };

  String get remove => switch (language) {
        AppLanguage.italian => 'Rimuovi',
        AppLanguage.english => 'Remove',
        AppLanguage.chinese => '移除',
      };

  String get proceedAnyway => switch (language) {
        AppLanguage.italian => 'Procedi comunque',
        AppLanguage.english => 'Proceed anyway',
        AppLanguage.chinese => '继续下单',
      };

  String unavailableItemsWarning(List<String> items) => switch (language) {
        AppLanguage.italian => 'I seguenti piatti non sono più disponibili:\n${items.join('\n')}\n\nVuoi rimuoverli dall\'ordine?',
        AppLanguage.english => 'The following items are no longer available:\n${items.join('\n')}\n\nDo you want to remove them?',
        AppLanguage.chinese => '以下菜品已无货：\n${items.join('\n')}\n\n是否从订单中移除？',
      };

  String get modified => switch (language) {
        AppLanguage.italian => 'MODIFICATO',
        AppLanguage.english => 'MODIFIED',
        AppLanguage.chinese => '已修改',
      };

  String get modifications => switch (language) {
        AppLanguage.italian => 'Modifiche',
        AppLanguage.english => 'Changes',
        AppLanguage.chinese => '修改',
      };

  // Day summary
  String get closeDay => switch (language) {
        AppLanguage.italian => 'Chiudi Giornata',
        AppLanguage.english => 'Close Day',
        AppLanguage.chinese => '结束营业',
      };

  String get daySummary => switch (language) {
        AppLanguage.italian => 'Riepilogo Giornata',
        AppLanguage.english => 'Day Summary',
        AppLanguage.chinese => '今日总结',
      };

  String get totalRevenue => switch (language) {
        AppLanguage.italian => 'Incasso Totale',
        AppLanguage.english => 'Total Revenue',
        AppLanguage.chinese => '总收入',
      };

  String get paidOrders => switch (language) {
        AppLanguage.italian => 'Ordini Pagati',
        AppLanguage.english => 'Paid Orders',
        AppLanguage.chinese => '已付订单',
      };

  String get totalCovers => switch (language) {
        AppLanguage.italian => 'Coperti Totali',
        AppLanguage.english => 'Total Covers',
        AppLanguage.chinese => '总人数',
      };

  String get averagePerOrder => switch (language) {
        AppLanguage.italian => 'Media per Ordine',
        AppLanguage.english => 'Average per Order',
        AppLanguage.chinese => '平均每单',
      };

  String get topDishes => switch (language) {
        AppLanguage.italian => 'Piatti più Ordinati',
        AppLanguage.english => 'Top Dishes',
        AppLanguage.chinese => '热门菜品',
      };

  String get noDataToday => switch (language) {
        AppLanguage.italian => 'Nessun dato per oggi',
        AppLanguage.english => 'No data for today',
        AppLanguage.chinese => '今日暂无数据',
      };

  // Analytics
  String get analytics => switch (language) {
        AppLanguage.italian => 'Statistiche',
        AppLanguage.english => 'Analytics',
        AppLanguage.chinese => '统计',
      };

  String get daily => switch (language) {
        AppLanguage.italian => 'Giorno',
        AppLanguage.english => 'Day',
        AppLanguage.chinese => '日',
      };

  String get monthly => switch (language) {
        AppLanguage.italian => 'Mese',
        AppLanguage.english => 'Month',
        AppLanguage.chinese => '月',
      };

  String get yearly => switch (language) {
        AppLanguage.italian => 'Anno',
        AppLanguage.english => 'Year',
        AppLanguage.chinese => '年',
      };

  String get tableOrdersLabel => switch (language) {
        AppLanguage.italian => 'Ordini Tavolo',
        AppLanguage.english => 'Table Orders',
        AppLanguage.chinese => '堂食订单',
      };

  String get takeawayOrdersLabel => switch (language) {
        AppLanguage.italian => 'Ordini Asporto',
        AppLanguage.english => 'Takeaway Orders',
        AppLanguage.chinese => '外卖订单',
      };

  String get revenueTrend => switch (language) {
        AppLanguage.italian => 'Andamento Incassi',
        AppLanguage.english => 'Revenue Trend',
        AppLanguage.chinese => '收入趋势',
      };

  String get dailyBreakdown => switch (language) {
        AppLanguage.italian => 'Dettaglio Giornaliero',
        AppLanguage.english => 'Daily Breakdown',
        AppLanguage.chinese => '每日明细',
      };

  String get exportExcel => switch (language) {
        AppLanguage.italian => 'Esporta Excel',
        AppLanguage.english => 'Export Excel',
        AppLanguage.chinese => '导出Excel',
      };

  String get exportSuccess => switch (language) {
        AppLanguage.italian => 'File salvato',
        AppLanguage.english => 'File saved',
        AppLanguage.chinese => '文件已保存',
      };

  String get exportError => switch (language) {
        AppLanguage.italian => 'Errore esportazione',
        AppLanguage.english => 'Export error',
        AppLanguage.chinese => '导出错误',
      };

  String get summarySaved => switch (language) {
        AppLanguage.italian => 'Riepilogo salvato',
        AppLanguage.english => 'Summary saved',
        AppLanguage.chinese => '总结已保存',
      };

  String get viewAnalytics => switch (language) {
        AppLanguage.italian => 'Vedi Statistiche',
        AppLanguage.english => 'View Analytics',
        AppLanguage.chinese => '查看统计',
      };

  // Served items
  String servedCount(int served, int total) => switch (language) {
        AppLanguage.italian => '$served/$total serviti',
        AppLanguage.english => '$served/$total served',
        AppLanguage.chinese => '已上$served/$total',
      };

  String servedCountShort(int served, int total) => switch (language) {
        AppLanguage.italian => '($served/$total ✓)',
        AppLanguage.english => '($served/$total ✓)',
        AppLanguage.chinese => '(已上$served/$total)',
      };

  // Cancel order
  String get cancelOrder => switch (language) {
        AppLanguage.italian => 'Annulla Ordine',
        AppLanguage.english => 'Cancel Order',
        AppLanguage.chinese => '取消订单',
      };

  String get cancelOrderConfirm => switch (language) {
        AppLanguage.italian => 'Sei sicuro di voler annullare questo ordine?',
        AppLanguage.english => 'Are you sure you want to cancel this order?',
        AppLanguage.chinese => '确定要取消此订单吗？',
      };

  String get orderCancelled => switch (language) {
        AppLanguage.italian => 'Ordine annullato',
        AppLanguage.english => 'Order cancelled',
        AppLanguage.chinese => '订单已取消',
      };

  String get confirm => switch (language) {
        AppLanguage.italian => 'Conferma',
        AppLanguage.english => 'Confirm',
        AppLanguage.chinese => '确认',
      };

  String get allServed => switch (language) {
        AppLanguage.italian => 'Tutti serviti',
        AppLanguage.english => 'All served',
        AppLanguage.chinese => '全部上齐',
      };

  String get deleteTableConfirm => switch (language) {
        AppLanguage.italian => 'Vuoi eliminare il tavolo',
        AppLanguage.english => 'Do you want to delete table',
        AppLanguage.chinese => '确定要删除餐桌',
      };

  // Error messages
  String get errorCreateOrder => switch (language) {
        AppLanguage.italian => 'Impossibile creare l\'ordine. Riprova.',
        AppLanguage.english => 'Unable to create order. Please try again.',
        AppLanguage.chinese => '无法创建订单，请重试。',
      };

  String get errorDeleteOrder => switch (language) {
        AppLanguage.italian => 'Impossibile eliminare l\'ordine. Riprova.',
        AppLanguage.english => 'Unable to delete order. Please try again.',
        AppLanguage.chinese => '无法删除订单，请重试。',
      };

  String get errorUpdateOrder => switch (language) {
        AppLanguage.italian => 'Impossibile modificare l\'ordine. Riprova.',
        AppLanguage.english => 'Unable to update order. Please try again.',
        AppLanguage.chinese => '无法修改订单，请重试。',
      };

  String get errorPaymentOrder => switch (language) {
        AppLanguage.italian => 'Impossibile segnare come pagato. Riprova.',
        AppLanguage.english => 'Unable to mark as paid. Please try again.',
        AppLanguage.chinese => '无法标记为已付款，请重试。',
      };

  String get errorCancelOrder => switch (language) {
        AppLanguage.italian => 'Impossibile annullare l\'ordine. Riprova.',
        AppLanguage.english => 'Unable to cancel order. Please try again.',
        AppLanguage.chinese => '无法取消订单，请重试。',
      };

  String get errorCreateTable => switch (language) {
        AppLanguage.italian => 'Impossibile creare il tavolo. Riprova.',
        AppLanguage.english => 'Unable to create table. Please try again.',
        AppLanguage.chinese => '无法创建餐桌，请重试。',
      };

  String get errorUpdateTable => switch (language) {
        AppLanguage.italian => 'Impossibile modificare il tavolo. Riprova.',
        AppLanguage.english => 'Unable to update table. Please try again.',
        AppLanguage.chinese => '无法修改餐桌，请重试。',
      };

  String get errorDeleteTable => switch (language) {
        AppLanguage.italian => 'Impossibile eliminare il tavolo. Riprova.',
        AppLanguage.english => 'Unable to delete table. Please try again.',
        AppLanguage.chinese => '无法删除餐桌，请重试。',
      };

  String get errorReservation => switch (language) {
        AppLanguage.italian => 'Impossibile prenotare il tavolo. Riprova.',
        AppLanguage.english => 'Unable to reserve table. Please try again.',
        AppLanguage.chinese => '无法预订餐桌，请重试。',
      };

  String get errorLoadOrders => switch (language) {
        AppLanguage.italian => 'Impossibile caricare gli ordini',
        AppLanguage.english => 'Unable to load orders',
        AppLanguage.chinese => '无法加载订单',
      };

  String get errorLoadTables => switch (language) {
        AppLanguage.italian => 'Impossibile caricare i tavoli',
        AppLanguage.english => 'Unable to load tables',
        AppLanguage.chinese => '无法加载餐桌',
      };

  String get checkConnection => switch (language) {
        AppLanguage.italian => 'Controlla la connessione internet',
        AppLanguage.english => 'Check your internet connection',
        AppLanguage.chinese => '请检查网络连接',
      };

  String get showBeverages => switch (language) {
        AppLanguage.italian => 'Mostra bevande',
        AppLanguage.english => 'Show beverages',
        AppLanguage.chinese => '显示饮料',
      };

  String get hideBeverages => switch (language) {
        AppLanguage.italian => 'Nascondi bevande',
        AppLanguage.english => 'Hide beverages',
        AppLanguage.chinese => '隐藏饮料',
      };

  String get textSize => switch (language) {
        AppLanguage.italian => 'Dimensione testo',
        AppLanguage.english => 'Text size',
        AppLanguage.chinese => '文字大小',
      };

  String get display => switch (language) {
        AppLanguage.italian => 'Visualizzazione',
        AppLanguage.english => 'Display',
        AppLanguage.chinese => '显示',
      };

  String get beveragesInOrders => switch (language) {
        AppLanguage.italian => 'Le bevande negli ordini',
        AppLanguage.english => 'Beverages in orders',
        AppLanguage.chinese => '订单中的饮料',
      };

  String get hideServedItemsLabel => switch (language) {
        AppLanguage.italian => 'Nascondi piatti serviti',
        AppLanguage.english => 'Hide served items',
        AppLanguage.chinese => '隐藏已上菜品',
      };

  String get hideServedItemsDesc => switch (language) {
        AppLanguage.italian => 'Nella lista ordini mostra solo i piatti da servire',
        AppLanguage.english => 'Show only items to be served in order list',
        AppLanguage.chinese => '订单列表中只显示待上菜品',
      };

  String get sampleText => switch (language) {
        AppLanguage.italian => 'Esempio testo',
        AppLanguage.english => 'Sample text',
        AppLanguage.chinese => '示例文字',
      };
}
