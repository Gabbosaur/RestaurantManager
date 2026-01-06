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
        AppLanguage.italian => 'Magazzino',
        AppLanguage.english => 'Inventory',
        AppLanguage.chinese => '库存',
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
        AppLanguage.italian => 'Servito',
        AppLanguage.english => 'Served',
        AppLanguage.chinese => '已上菜',
      };

  String get cancelled => switch (language) {
        AppLanguage.italian => 'Annullato',
        AppLanguage.english => 'Cancelled',
        AppLanguage.chinese => '已取消',
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
}
