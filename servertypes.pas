unit servertypes;

interface

{$A-}

const srvversion          = 9;                               // версия сервера

const msgKot              = $00;                             // типы запросов клиента
      msgSetOrd           = $01;
      msgEditOrd          = $02;
      msgDropOrd          = $03;
      msgAllTrades        = $04;
      msgQueryReport      = $05;
      msgQueryTrades      = $06;
      msgAllTradesReq     = $07;

const opNormal            = $00000000;                       // типы заявок
      opImmCancel         = $00000001;
      opMarketPrice       = $00000002;
      opWDRest            = $00000004;
      opDelayed           = $00000008;
      opMarging           = $00000010;
      opRpsDeal           = $00000020;
      opAuct              = $00000040;
      opRepoDeal          = $00000080;
      opCCP               = $00000100;

const errNoErrors         = $00;
      errSetOrderOK       = $01;
      errDropOrderOK      = $02;
      errEditOrderOK      = $03;
      errUnsupportedFn    = $04;
      errUnknownAccnt     = $05;
      errInvalidAccnt     = $06;
      errNoMoney          = $07;
      errInvalidDropPk    = $08;
      errNotEncrypted     = $09;
      errInvalidStock     = $0a;
      errDecryptFail      = $0b;
      errStockUnavail     = $0c;
      errDemoUser         = $0d;
      errMarginDisabled   = $0e;
      errNoSuchOrder      = $0f;
      errDecompressFail   = $10;
      errMonitorMode      = $11;
      errMarginLimit      = $12;
      errBCaseDemoLimit   = $13;
      errWaitTrades       = $14;
      errInvalidPeriod    = $15;
      errUnknownTrans     = $16;
      errFrozenAccnt      = $17;
      errRepoNotAllowed   = $18;
      errBrokerLimit      = $19;
      errNotAllowed       = $1a;
      errInvalidMarginAcc = $1b;
      errIncompleteTrs    = $1c;
      errUnsupportedStop  = $1d;
      errNotLiquid        = $1e;
      errStockReply       = $ff;

const soAccepted          = $00;                             // заявка поставлена
      soRejected          = $01;                             // заявка отклонена
      soUnknown           = $02;                             // неизвестный результат
      soDropAccepted      = $03;                             // заявка снята
      soDropRejected      = $04;                             // снятие заявки отклонено
      soError             = $ff;                             // ошибка транзакции

const maxDropOrders       = 7;                               // макс. количество заявок для сброса в структуре tClientQuery

const stockNone           = $00;
      stockView           = $01;
      stockWork           = $02;

const sfAddToList         = $00;                             // добавить в список активных для соединения
      sfDelFromList       = $01;                             // удалить из списка активных для соединения
      sfSendOnly          = $02;                             // не трогать списки, только послать

const sfSendKot           = $01;
      sfSendAllTrades     = $02;
      sfSendSecurities    = $04;

const dayWasOpened        = $01;                             // сессия была открыта
      dayWasClosed        = $02;                             // сессия была закрыта

                                                             // условия исполнения стоп-заявок
const stopLowerOrEqual    = $00;                             // lowoffer        <= value
      stopHigherOrEqual   = $01;                             // hibid           >= value

      stopOfferLOE        = stopLowerOrEqual;                // lowoffer        <= value
      stopOfferHOE        = $02;                             // lowoffer        >= value
      stopBidLOE          = $03;                             // hibid           <= value
      stopBidHOE          = stopHigherOrEqual;               // hibid           >= value
      stopLastSecLOE      = $04;                             // lastprice       <= value
      stopLastSecHOE      = $05;                             // lastprice       >= value

      stopLastAllTrdLOE   = $06;                             // alltrades.price <= value
      stopLastAllTrdHOE   = $07;                             // alltrades.price >= value

const dropNormalOrders    = $0000;                           // пакет содержит обычные заявки для снятия
      dropStopOrders      = $0001;                           // пакет содержит стоп-заявки для снятия

const newsQueryByDate     = $0000;                           // запрос идентификаторов новостей по дате
      newsQueryByID       = $0001;                           // запрос идентификаторов новостей по номеру
      newsQueryText       = $0002;                           // запрос текста новости по идентификатору

const marginNormal        = $0000;                           // нормальный у.м.
      marginBelowNormal   = $0001;                           // у.м. ниже нормального
      marginBelowWarning  = $0002;                           // у.м. ниже предупредительного
      marginBelowCritical = $0003;                           // у.м. ниже критического

const levelShares         = $0000;                           // акции
      levelBonds          = $0001;                           // облигации
      levelFutures        = $0002;                           // фьючерсы
      levelOptions        = $0003;                           // опционы

const acntViewOnly        = $0000;                           // счет только для просмотра
      acntAllowTrade      = $0001;                           // разрешена торговля
      acntAllowMargin     = $0002;                           // разрешен маржинг

const acnttypeNormal      = $0000;                           // обычный счет
      acnttypePrepared    = $0001;                           // счет рассчитывается ТС биржи

type  tTransactionID      = longint;

type  pTrsQueryID         = ^tTrsQueryID;
      tTrsQueryID         = int64;

type  pClientID           = ^tClientID;
      tClientID           = string[5];                       // идентификатор клиента

type  pAccount            = ^tAccount;
      tAccount            = string[20];                      // счет клиента

type  pMarketCode         = ^tMarketCode;
      tMarketCode         = string[3];                       // код рынка

type  pLevel              = ^tLevel;
      tLevel              = string[4];                       // тип бумаги

type  pCode               = ^tCode;                          // код бумаги
      tCode               = string[20];

type  pShortName          = ^tShortName;                     // наименование бумаги
      tShortName          = string[20];

type  pComment            = ^tComment;                       // комментарий
      tComment            = string[30];

type  pUserName           = ^tUserName;                      // имя пользователя
      tUserName           = string[20];

type  pSettleCode         = ^tSettleCode;                    // код расчетов
      tSettleCode         = string[3];

type  pSecIdent           = ^tSecIdent;
      tSecIdent           = record
       stock_id           : longint;                         // идент. торговой площадки
       level              : tLevel;                          // тип ценной бумаги
       code               : tCode;                           // уникальный код ценной бумаги
      end;

type  pBoardIdent         = ^tBoardIdent;
      tBoardIdent         = record
       stock_id           : longint;                         // идент. торговой площадки
       level              : tLevel;                          // тип ценной бумаги
      end;

type  pSettleCodes        = ^tSettleCodes;
      tSettleCodes        = record
       stock_id           : longint;
       settlecode         : tSettleCode;
       description        : string[40];
       settledate1        : tDateTime;
       settledate2        : tDateTime;
      end;

type  tFirmSet            = set of (fid_stock_id, fid_firmid, fid_firmname, fid_status);

type  pFirmIdent          = ^tFirmIdent;
      tFirmIdent          = record
       stock_id           : longint;
       firmid             : string[20];
       firmname           : string[40];
       status             : char;
      end;

type  pFirmItem           = ^tFirmItem;
      tFirmItem           = record
       firm               : tFirmIdent;                      // фирма
       firmset            : tFirmSet;                        // валидные поля
      end;

type  tSecuritiesSet      = set of (sec_stock_id,sec_shortname,sec_level,sec_code,sec_hibid, sec_lowoffer,
                                    sec_initprice,sec_maxprice,sec_minprice,sec_meanprice,sec_meantype,
                                    sec_change,sec_value,sec_amount,sec_lotsize,sec_facevalue,sec_lastdealprice,
                                    sec_lastdealsize,sec_lastdealqty,sec_lastdealtime,sec_gko_accr,sec_gko_yield,
                                    sec_gko_matdate,sec_gko_cuponval,sec_gko_nextcupon,sec_gko_cuponperiod,
                                    sec_srv_field,sec_biddepth,sec_offerdepth,sec_numbids,sec_numoffers,
                                    sec_tradingstatus,sec_closeprice,sec_gko_issuesize,sec_gko_buybackprice,
                                    sec_gko_buybackdate,sec_prev_price,sec_fut_deposit,sec_fut_openedpos,
                                    sec_marketprice, sec_limitpricehigh, sec_limitpricelow, sec_decimals,
                                    sec_pricestep, sec_stepprice);

type  pSecurities         = ^tSecurities;
      tSecurities         = record
       stock_id           : longint;                         // идент. торговой площадки
       shortname          : tShortName;                      // название инструмента
       level              : tLevel;                          // тип ценной бумаги
       code               : tCode;                           // уникальный код ценной бумаги
       hibid              : real;                            // спрос
       lowoffer           : real;                            // предложение
       initprice          : real;                            // цена открытия
       maxprice           : real;                            // макс. цена ценной бумаги
       minprice           : real;                            // мин. цена ценной бумаги
       meanprice          : real;                            // средневзвешенная цена
       meantype           : byte;                            // тип расчета средневзв.
       change             : real;                            // изменение (к закрытию)
       value              : int64;                           // объем торгов за тек. день в рублях
       amount             : int64;                           // объем торгов за тек. день в бумагах
       lotsize            : longint;                         // размер лота
       facevalue          : real;                            // номинал
       lastdealprice      : real;                            // цена при последней сделке
       lastdealsize       : real;                            // объем последней сделки в рублях
       lastdealqty        : longint;                         // объем последней сделки в лотах
       lastdealtime       : double;                          // время последней сделки
       gko_accr           : real;                            // накопленный доход
       gko_yield          : currency;                        // доходность гко
       gko_matdate        : double;                          // дата погашения гко
       gko_cuponval       : currency;                        // величина купона
       gko_nextcupon      : double;                          // дата выплаты купона
       gko_cuponperiod    : longint;                         // длительность купона
       biddepth           : int64;                           // объем всех заявок на покупку
       offerdepth         : int64;                           // объем всех заявок на продажу
       numbids            : longint;                         // количество заявок на покупку в очереди ТС в лотах
       numoffers          : longint;                         // количество заявок на продажу в очереди ТС в лотах
       tradingstatus      : char;                            // состояние торгов по финансовому инструменту
       closeprice         : real;                            // цена закрытия
       srv_field          : string[10];                      // служебное поле
       gko_issuesize      : int64;                           // объем обращения
       gko_buybackprice   : real;                            // цена оферты
       gko_buybackdate    : double;                          // дата оферты
       prev_price         : real;                            // котировка предыдущей сессии
       fut_deposit        : real;                            // гарантийное обеспечение
       fut_openedpos      : int64;                           // кол-во открытых позиций
       marketprice        : real;                            // рыночная цена предыдущего дня
       limitpricehigh     : real;                            // верхний лимит цены
       limitpricelow      : real;                            // нижний лимит цены
       decimals           : longint;                         // количество знаков после запятой
       pricestep          : real;                            // минимальный шаг цены
       stepprice          : real;                            // стоимость минимального шага цены
      end;

type  pSecuritiesItem     = ^tSecuritiesItem;
      tSecuritiesItem     = record
       sec                : tSecurities;                     // фин. инструмент
       secset             : tSecuritiesSet;                  // валидные поля
      end;

type  pKotirovki          = ^tKotirovki;
      tKotirovki          = record
       stock_id           : longint;                         // идент. торговой площадки
       level              : tLevel;                          // тип ценной бумаги
       code               : tCode;                           // уникальный код ценной бумаги
       buysell            : char;                            // купля/продажа
       price              : real;                            // цена
       quantity           : longint;                         // количество
       gko_yield          : currency;                        // доходность гко
      end;

type  pKotUpdateHdr       = ^tKotUpdateHdr;
      tKotUpdateHdr       = record
       stock_id           : longint;                         // идент. торговой площадки
       level              : tLevel;                          // тип ценной бумаги
       code               : tCode;                           // уникальный код ценной бумаги
       kotcount           : longint;                         // кол-во котировок в апдейте
      end;

      pKotUpdateItem      = ^tKotUpdateItem;
      tKotUpdateItem      = record
       buysell            : char;                            // купля/продажа
       price              : real;                            // цена
       quantity           : longint;                         // количество
       gko_yield          : currency;                        // доходность гко
      end;

type  tOrdersSet          = set of (ord_stock_id,ord_level,ord_code,ord_orderno,ord_ordertime,ord_status,
                                    ord_buysell,ord_account,ord_price,ord_quantity,ord_value,ord_clientid,
                                    ord_balance,ord_ordertype,ord_settlecode,ord_comment);

type  pOrders             = ^tOrders;
      tOrders             = record
       transaction        : tTransactionID;                  // номер транзакции
       internalid         : tTransactionID;                  // номер поручения
       stock_id           : longint;                         // идент. торговой площадки
       level              : tLevel;                          // тип ценной бумаги
       code               : tCode;                           // уникальный код ценной бумаги
       orderno            : int64;                           // номер заявки в торговой системе
       ordertime          : double;                          // Время постановки заявки
       status             : char;                            // Состояние заявки
       buysell            : char;                            // Купля/продажа
       account            : tAccount;                        // Счет
       price              : real;                            // Цена
       quantity           : longint;                         // Кол-во
       value              : real;                            // Объем
       clientid           : tClientID;                       // ID клиента
       balance            : longint;                         // Остаток по заявке
       ordertype          : char;                            // тип заявки (обычная, РПС, РЕПО)
       settlecode         : tSettleCode;                     // код расчетов
       comment            : tComment;                        // Комментарий к заявке
      end;

type  pOrdCollItm       = ^tOrdCollItm;
      tOrdCollItm       = record
        ord             : tOrders;
        ordset          : tOrdersSet;
      end;

type  tTradesSet          = set of (trd_stock_id,trd_tradeno,trd_orderno,trd_tradetime,trd_level,trd_code,
                                    trd_buysell,trd_account,trd_price,trd_quantity,trd_value,trd_accr,
                                    trd_clientid,trd_tradetype,trd_settlecode,trd_comment);

type  pTrades             = ^tTrades;
      tTrades             = record
       transaction        : tTransactionID;                  // номер транзакции
       internalid         : tTransactionID;                  // номер поручения
       stock_id           : longint;                         // идент. торговой площадки
       tradeno            : int64;                           // номер сделки
       orderno            : int64;                           // номер заявки
       tradetime          : double;                          // время сделки
       level              : tLevel;                          // тип ценной бумаги
       code               : tCode;                           // уникальный код ценной бумаги
       buysell            : char;                            // Купля/продажа
       account            : tAccount;                        // Счет
       price              : real;                            // Цена
       quantity           : longint;                         // Кол-во
       value              : real;                            // Объем
       accr               : real;                            // накопленный доход
       clientid           : tClientID;                       // ID клиента
       tradetype          : char;                            // тип сделки (обычная, РПС, РЕПО)
       settlecode         : tSettleCode;                     // код расчетов
       comment            : tComment;                        // Комментарий к сделке
      end;

type  pTrdCollItm       = ^tTrdCollItm;
      tTrdCollItm       = record
        trd             : tTrades;
        trdset          : tTradesSet;
      end;

type  pAllTrades          = ^tAllTrades;
      tAllTrades          = record
       stock_id           : longint;                         // идент. торговой площадки
       tradeno            : int64;                           // номер сделки
       tradetime          : double;                          // время сделки
       level              : tLevel;                          // тип ценной бумаги
       code               : tCode;                           // уникальный код ценной бумаги
       price              : real;                            // Цена
       quantity           : longint;                         // Кол-во
       value              : real;                            // Объем
       buysell            : char;                            // Инициатор сделки
       reporate           : real;                            // Ставка РЕПО в %
       repoterm           : longint;                         // Срок РЕПО в календарных днях
      end;

type  tLimitsSet          = set of (lim_account, lim_stock_id, lim_code, lim_oldlimit, lim_startlimit, lim_free,
                                    lim_reserved, lim_res_pos, lim_res_ord, lim_negvarmarg, lim_curvarmarg);

type  pClientLimit        = ^tClientLimit;
      tClientLimit        = record
       account            : tAccount;                        // счет
       stock_id           : longint;                         // идент. торговой площадки
       code               : tCode;                           // уникальный код ценной бумаги
       oldlimit           : currency;                        // лимит предыдущей торговой сессии
       startlimit         : currency;                        // текущий лимит
       free               : currency;                        // свободных средств
       reserved           : currency;                        // зарезервировано всего
       res_pos            : currency;                        // зарезервировано под позиции
       res_ord            : currency;                        // зарезервировано под заявки
       negvarmarg         : currency;                        // отрицательная вариационная маржа
       curvarmarg         : currency;                        // вариационная маржа
      end;

type  pClientLimitItem    = ^tClientLimitItem;
      tClientLimitItem    = record
        limit             : tClientLimit;                    // лимит
        limitset          : tLimitsSet;                      // валидные поля
      end;

type  pArcTradeBuf        = ^tArcTradeBuf;
      tArcTradeBuf        = record
       account            : tAccount;                        // Счет
       stock_id           : longint;                         // идент. торговой площадки
       code               : tCode;                           // уникальный код ценной бумаги
       rowcount           : longint;
      end;

      pArcTradeRow        = ^tArcTradeRow;
      tArcTradeRow        = record
       tradeno            : int64;                           // номер сделки
       tradetime          : double;                          // время сделки
       price              : real;                            // Цена
       quantity           : longint;                         // Кол-во
       accr               : real;                            // накопленный доход
      end;

type  pLevelAttrItem     = ^tLevelAttrItem;                  // список рынков
      tLevelAttrItem     = record
       stock_id          : longint;                          // идент. торговой площадки
       level             : tLevel;                           // тип ценной бумаги
       usefacevalue      : boolean;                          // использование номинала
       marketcode        : tMarketCode;                      // код рынка
       leveltype         : longint;                          // тип рынка (см константы level*)
       default           : longint;                          // признак "рынок по умолчинию"
       description       : string[50];                       // текстовое описание
      end;

type  pMarginInfo         = ^tMarginInfo;                    // значения уровней маржи
      tMarginInfo         = record
       normal             : real;
       warning            : real;
       critical           : real;
      end;

type  pAccountListItm     = ^tAccountListItm;                // список счетов
      tAccountListItm     = record
       stock_id           : longint;                         // идент. торговой площадки
       account            : tAccount;                        // счет
       flags              : longint;                         // флаги
       margininfo         : tMarginInfo;                     // информация об индивидуальных уровнях
       descr              : string[100];                     // описание счета
      end;

type  pStockAccListItm    = ^tStockAccListItm;               // список биржевых счетов
      tStockAccListItm    = record
       stock_id           : longint;                         // идент. торговой площадки
       account            : tAccount;                        // счет
       marketcode         : tMarketCode;                     // код рынка
       stockaccount       : tAccount;                        // счет на бирже
       default            : boolean;                         // признак счета по-умолчанию для обратного преобразования
       account_type       : longint;                         // тип счета
      end;

type  tMargLevel          = ( margin_normal,                 // нормальный уровень маржи
                              margin_warning,                // предупредительный уровень маржи
                              margin_critical );             // критический уровень маржи

type  pMarginLevel        = ^tMarginLevel;                   // текущий уровень маржи
      tMarginLevel        = record
       account            : tAccount;                        // номер счета
       factlvl            : real;                            // фактический у.м.
       planlvl            : real;                            // плановый у.м.
       minlvl             : real;                            // минимальный у.м.
       marginstate        : longint;                         // статус относительно ограничительных уровней
       planlvlb           : real;                            // плановый у.м. в сторону покупки
       planlvls           : real;                            // плановый у.м. в сторону продажи
       planlvlmid         : real;                            // плановый у.м. без учета продаж неликвидов
       planlvlbn          : real;                            // плановый у.м. в сторону покупки в случае неликвида
      end;

type  tAccountSet         = set of (acc_stock_id, acc_code, acc_fact, acc_plan, acc_fdbt, acc_pdbt, acc_reserved,
                                    acc_res_pos, acc_res_ord, acc_negvarmarg, acc_curvarmarg);

type  pAccountBuf         = ^tAccountBuf;
      tAccountBuf         = record                           // ресурсы на счету
       account            : tAccount;                        // счет
       rowcount           : longint;                         // количество строк в счете
      end;

      pAccountRow         = ^tAccountRow;
      tAccountRow         = record
       fields             : tAccountSet;                     // поля
       // общие поля
       stock_id           : longint;                         // биржа
       code               : tCode;                           // код бумаги
       // фондовый рынок
       fact               : currency;                        // фактический остаток
       plan               : currency;                        // плановый остаток
       fdbt               : currency;                        // фактическая задолженность
       pdbt               : currency;                        // плановая задолженность
       // срочный рынок
       reserved           : currency;                        // зарезервировано всего
       res_pos            : currency;                        // зарезервировано под позиции
       res_ord            : currency;                        // зарезервировано под заявки
       negvarmarg         : currency;                        // отрицательная вариационная маржа
       curvarmarg         : currency;                        // текущая вариационная маржа
      end;

type  pAccountRestsBuf    = ^tAccountRestsBuf;
      tAccountRestsBuf    = record                           // остатки на счету
       account            : tAccount;                        // счет
       rowcount           : longint;                         // количество строк в счете
      end;

      pAccountRestsRow    = ^tAccountRestsRow;               // остатки на начало дня
      tAccountRestsRow    = record
       stock_id           : longint;                         // биржа
       code               : tCode;                           // код бумаги
       fact               : currency;                        // остаток
       avgprice           : currency;                        // средняя цена покупки
      end;

type  pLiquidListItem     = ^tLiquidListItem;
      tLiquidListItem     = record                           // список ликвидных бумаг
       stock_id           : longint;                         // биржа
       level              : tLevel;                          // тип ценной бумаги
       code               : tCode;                           // код бумаги
       price              : real;                            // цена бумаги
       hibid              : real;                            // спрос
       lowoffer           : real;                            // предложение
       repolevel          : tLevel;                          // рынок, на котором совершаются сдклки РПC
      end;

type  pOrder              = ^tOrder;                         // заявка (запрос)
      tOrder              = record
       transaction        : tTransactionID;                  // номер транзакции
       stock_id           : longint;                         // идентификатор торговой площадки
       level              : tLevel;                          // рынок
       code               : tCode;                           // код бумаги
       buysell            : char;                            // покупка/продажа
       price              : real;                            // цена за бумагу
       quantity           : longint;                         // количество в лотах
       account            : tAccount;                        // счет
       flags              : longint;                         // флаги заявки
       cid                : tClientId;                       // идентификатор клиента
       cfirmid            : string[20];                      // идентификатор фирмы для заключения РЕПО/РПС
       match              : string[20];                      // ссылка для РЕПО/РПС
       settlecode         : tSettleCode;                     // код расчетов
       refundrate         : real;                            // возмещение
       reporate           : real;                            // ставка РЕПО
       price2             : real;                            // цена выкупа РЕПО
      end;

type  pMoveOrder          = ^tMoveOrder;                     // запрос на перенос заявки
      tMoveOrder          = record
       transaction        : tTransactionID;                  // номер транзакции
       stock_id           : longint;                         // идентификатор площадки
       level              : tLevel;                          // рынок
       code               : tCode;                           // код бумаги
       orderno            : int64;                           // номер модифицируемой заявки
       new_price          : real;                            // новая цена
       new_quantity       : longint;                         // новое количество
       account            : tAccount;                        // счет
       flags              : longint;                         // флаги переноса транзакции
       cid                : tClientId;                       // идентификатор клиента
      end;

type  pDropOrderEx        = ^tDropOrderEx;                   // запрос на снятие заявки
      tDropOrderEx        = record
       transaction        : tTransactionID;                  // номер транзакции
       orderno            : int64;                           // номер снимаемой заявки
       stock_id           : longint;                         // идентификатор площадки
       level              : TLevel;                          // рынок
       code               : TCode;                           // код бумаги
       account            : tAccount;                        // счет
       flags              : longint;                         // флаги снятия заявки
       cid                : tClientId;                       // идентификатор клиента
      end;

type  pStopOrder          = ^tStopOrder;                     // стоп-заявка (запрос)
      tStopOrder          = record
       order              : tOrder;                          // заявка
       stoptype           : byte;                            // условие срабатывания
       stopprice          : real;                            // цена срабатывания
       expiredatetime     : tdatetime;                       // дата и время снятия заявки
      end;

type  pStopOrders         = ^tStopOrders;                    // стоп-заявки
      tStopOrders         = record
       stopid             : int64;                           // номер
       stoptime           : tdatetime;                       // время заявки
       stoporder          : tStopOrder;                      // стоп-заявка
       status             : char;                            // статус
       so_clientid        : tClientId;                       // идентификатор клиента
       so_username        : tUserName;                       // имя пользователя
       so_ucf             : longint;                         //
       so_sf              : longint;                         //
       comment            : tComment;                        // комментарий
      end;

type  tNewsSet            = set of (nws_newsprovider, nws_newstime);

type  pNewsHeader         = ^tNewsHeader;
      tNewsHeader         = record
       id                 : longint;                         // уникальный идентификатор новости
       news_id            : longint;                         // идентификатор поставщика
       newstime           : tDateTime;                       // время события
       newsfields         : tNewsSet;                        // заполненные поля
       subjlen            : longint;                         // длинна темы
       textlen            : longint;                         // длинна текста
      end;                                                   // тесктовые поля следом за структурой

type  pNewsQuery          = ^tNewsQuery;
      tNewsQuery          = record
       lastid             : longint;                         // идентификатор новости
       lastdate           : tDateTime;                       // дата/время последней новости
       querytype          : longint;                         // тип запроса
      end;

type  tOrderComment       = string[20];

type  tOrdersArray        = array [1..maxDropOrders] of int64;

type  pDropOrder          = ^tDropOrder;
      tDropOrder          = record
       transaction        : tTrsQueryID;
       stock_id           : word;                            // идентификатор торговой площадки. word для совместимости
       dropflags          : word;                            // флаги: стоп заявки или обычные
       count              : byte;
       orders             : tOrdersArray;
      end;

      tAllTradesSw        = record
       TradesFlag         : boolean;
       stock_id           : longint;
       LastTrade          : int64;
      end;

      tReportQuery        = record
       account            : tAccount;
       sdate,fdate        : tDateTime;
      end;

      tTradesQuery        = record
       account            : tAccount;
       stock_id           : longint;
       code               : tCode;
       quantity           : longint;
      end;

      pClientQuery        = ^tClientQuery;
      tClientQuery        = record                           // Команда от клиента
       case msgid         : byte of
        msgKot            : (add          : byte;
                             secid        : tSecIdent);
        msgAllTrades      : (TradesSwitch : tAllTradesSw);
        msgSetOrd         : (SetOrder     : tOrder);
        msgEditOrd        : (EditOrder    : tOrder);
        msgDropOrd        : (DropOrder    : tDropOrder);
        msgQueryReport    : (ReportQuery  : tReportQuery);
        msgQueryTrades    : (TradesQuery  : tTradesQuery);
        msgAllTradesReq   : (atrdadd      : byte;
                             atrdboardid  : tBoardIdent;
                             atrdtradeno  : int64);
      end;

type  pSetOrderResult     = ^tSetOrderResult;
      tSetOrderResult     = record
       // поля, в которых возвращается результат
       accepted           : byte;                            // принята ли заявка
       ExtNumber          : int64;                           // номер заявки
       TEReply            : string[235];                     // текстовое сообщение торговой площадки
       Quantity           : int64;                           // кол-во (в заявке после снятия, исполнено...), зависит от транзакции
       Reserved           : int64;                           // зарезервировано
       // служебные поля которые должны сохраняться
       ID                 : longint;                         // определяется пользователем
       clientid           : tClientId;                       // идентификатор клиента
       username           : tUserName;                       // имя пользователя
       account            : tAccount;                        // счет в системе
       internalid         : tTransactionID;                  // внутренний номер транзакции
       externaltrs        : tTransactionID;                  // номер транзакции внешней системы
      end;

type  pTrsQuery           = ^tTrsQuery;
      tTrsQuery           = array[0..0] of tTrsQueryID;      // список запрашиваемых транзакций

type  pTrsResult          = ^tTrsResult;
      tTrsResult          = record
       transaction        : tTrsQueryID;                     // номер транзакции
       errcode            : byte;                            // код возврата
       quantity           : int64;                           // кол-во
       reserved           : int64;                           // зарезервировано
      end;                                                   // тесктовое сообщение следом за структурой

type  pReportHeader       = ^tReportHeader;
      tReportHeader       = record                           // заголовок отчета
       sdat               : tdatetime;                       // начальная дата
       fdat               : tdatetime;                       // конечная дата
       fullname           : string[50];                      // информация о клиенте
       address            : string[50];                      // информация о площадке
       prcnds             : real;                            // множитель НДС
       rowcount           : longint;                         // счетчик строк
      end;

      pReportRow          = ^tReportRow;
      tReportRow          = record                           // строка отчета
       transaction        : tTransactionID;                  // транзакция (номер поручения)
       trstype            : char;                            // тип данных
       dealid             : int64;                           // номер сделки
       dt                 : tDateTime;                       // время
       stock_id           : longint;                         // идентификатор торговой площадки
       code               : tCode;                           // код ценной бумаги
       shortname          : tShortName;                      // наименование инструмента
       buysell            : char;                            // покупка/продажа
       price              : real;                            // цена
       quantity           : currency;                        // количество
       value              : currency;                        // объем
       nkd                : currency;                        // купонный доход
       stockkommiss       : currency;                        // комиссия биржи
       brokerkommiss      : currency;                        // комиссия брокера
       comment            : string[100];                     // комментарий
      end;

type  pStockRow           = ^tStockRow;                      // описание торговой площадки
      tStockRow           = record
       stock_id           : longint;                         // идентификатор торговой площадки
       stock_name         : string[20];                      // наименование
       stock_flags        : byte;                            // флаги (доступность и так далее)
      end;

type  pSecFlagsItm        = ^tSecFlagsItm;
      tSecFlagsItm        = record
       secid              : tSecIdent;
       flags              : longint;
       lasttradeno        : int64;
      end;

type  pQueueData          = ^tQueueData;
      tQueueData          = record
       id                 : longint;
       size               : longint;
       cnt                : longint;
       data               : pChar;
      end;

type  pIndLimitsBuf       = ^tIndLimitsBuf;                  // индивидуальные лимиты
      tIndLimitsBuf       = record
       account            : tAccount;                        // счет
       rowcount           : longint;                         // кол-во строк с инд. лимитами
      end;

      pIndLimitsRow       = ^tIndLimitsRow;                  // индивидуальный лимит
      tIndLimitsRow       = record
       stock_id           : longint;                         // идентификатор торговой площадки
       code               : tCode;                           // код бумаги
       limit              : currency;                        // значение лимита
      end;

const allsecuritiesfields : tSecuritiesSet = [sec_stock_id,sec_shortname, sec_level,sec_code,sec_hibid,
                                              sec_lowoffer,sec_initprice,sec_maxprice,sec_minprice,sec_meanprice,
                                              sec_meantype,sec_change,sec_value,sec_amount,sec_lotsize,sec_facevalue,
                                              sec_lastdealprice,sec_lastdealsize,sec_lastdealqty,sec_lastdealtime,
                                              sec_gko_accr,sec_gko_yield,sec_gko_matdate,sec_gko_cuponval,
                                              sec_gko_nextcupon,sec_gko_cuponperiod,sec_srv_field,sec_biddepth,
                                              sec_offerdepth,sec_numbids,sec_numoffers,sec_tradingstatus,sec_closeprice,
                                              sec_gko_issuesize, sec_gko_buybackprice, sec_gko_buybackdate,
                                              sec_prev_price,sec_fut_deposit,sec_fut_openedpos,sec_marketprice,
                                              sec_limitpricehigh,sec_limitpricelow, sec_decimals, sec_pricestep,
                                              sec_stepprice];

const allordersfields     : tOrdersSet     = [ord_stock_id,ord_level,ord_code,ord_orderno,ord_ordertime,
                                              ord_status,ord_buysell,ord_account,ord_price,ord_quantity,
                                              ord_value,ord_clientid,ord_balance,ord_ordertype,ord_comment];

const alltradesfields     : tTradesSet     = [trd_stock_id,trd_tradeno,trd_orderno,trd_tradetime,trd_level,
                                              trd_code,trd_buysell,trd_account,trd_price,trd_quantity,trd_value,
                                              trd_accr,trd_clientid,trd_tradetype,trd_comment];

implementation

end.


