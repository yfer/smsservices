library smsru;

import 'package:http/http.dart' as http;
import 'dart:async';

class authorization{
  static const API_ID = const authorization._(0);
  static const LOGIN_PASSWORD = const authorization._(1);
  static const SECURE = const authorization._(2);
  
  static get values => [API_ID, LOGIN_PASSWORD, SECURE];

  final int value;

  const authorization._(this.value);
}
/**
 * Класс для работы с сервисом рассылки SMS sms.ru
 */
class smsru{
  /// api_id из личного кабинета
  final String _api_id;  
  
  /**
   * api_id. Это единственный способ авторизации на данный момент
   */
  smsru(String this._api_id, {authorization method : authorization.API_ID});

  /**
   * Узнать сколько будет стоить SMS на номер [to] с текстом [text].
   * Возвращает ассоциативный массив со значениями:
   * Если текст не введен, то возвращается стоимость 1 сообщения. Если текст введен, то возвращается стоимость, рассчитанная по длине сообщения. 
   */
  Future<Map<String,int>> cost(String to, String text) => _send(http.post, _COST_URL, {"to":to, "text":text})
      .then( (x)=>{"cost":x[1],"count":x[2]} );
  
  /**
   * Статус SMS с идентификатором [id];
   * В массиве [messages] содержится текстовое описание сообщения.
   */
  Future<int> status(int id) => _send(http.post, _STATUS_URL, {"id":id}).then( (x)=>x[0] );
  
  /**
   * Текущий баланс;
   */
  Future<int> balance() => _send(http.post, _BALANCE_URL).then( (x) => x[1] );
  
  /**
   * Лимит затрат за день;
   */
  Future<int> limit() => _send(http.post, _LIMIT_URL).then( (x) => x[1] );  
  
  /**
   * Отправить до 100 SMS;
   * 
   * [messages]: Map<String,String> with key=phone number and value = message to sent
   * [from]: String; 
   * [time]: DateTime;
   * [translit]:
   * [test]:
   * [partner_id]:
   * 
   * return List<String> containing id's of messages;
   */
  Future<List<String>> send(Map<String,String> messages, {String from, DateTime time, bool translit, bool test, int partner_id}){
    var options = {};
    if(messages!=null) messages.forEach( (k,v)=> options["multi[$k]"]=v );
    if(time!=null) options["time"] = time.millisecondsSinceEpoch;
    if(from!=null) options["from"] = from;
    if(translit!=null) options["translit"] = translit?"1":"0";
    if(test!=null) options["test"] = test?"1":"0";
    if(partner_id!=null) options["partner_id"] = partner_id;   
    return _send(http.post, _SEND_URL, options).then( (x) => x.getRange(1, x.length-1));
  }

  dynamic _send(Function func, dynamic url, [Map<String,String> parameters = const {}]){
    var body = {
      "api_id":_api_id
    }..addAll(parameters);
    return func(url, body:body).then((response){
      List<String> rows = response.body.split("\n");
      int code = int.parse(rows.first);
      if(code>=200 || code==-1)
        throw new Exception(messages[code]);
      return rows;
    });
  }
  static const String _BASE_URL = "http://sms.ru";
  static const String _SEND_URL = "$_BASE_URL/sms/send";
  static const String _COST_URL = "$_BASE_URL/sms/cost";
  static const String _STATUS_URL = "$_BASE_URL/sms/status";
  static const String _BALANCE_URL = "$_BASE_URL/my/balance";
  static const String _LIMIT_URL = "$_BASE_URL/my/limit";
}
const Map<int,String> messages = const {
  -1  : "Сообщение не найдено.",
  // sms/send    : "Сообщение принято к отправке. На следующих строчках вы найдете идентификаторы отправленных сообщений в том же порядке, в котором вы указали номера, на которых совершалась отправка."
  // sms/status  : "Сообщение находится в нашей очереди"
  // sms/cost    : "Запрос выполнен. На второй строчке будет указана стоимость сообщения. На третьей строчке будет указана его длина."
  // my/balance  : "Запрос выполнен. На второй строчке вы найдете ваше текущее состояние баланса."
  // my/limit    : "100 Запрос выполнен. На второй строчке вы найдете ваше текущее дневное ограничение. На третьей строчке количество сообщений, отправленных вами в текущий день."
  // my/senders  : "Запрос выполнен. На второй и последующих строчках вы найдете ваших одобренных отправителей, которые можно использовать в параметре &from= метода sms/send."
  // auth/check  : "ОК, номер телефона и пароль совпадают."
  // stoplist/add: "Номер добавлен в стоплист."
  // stoplist/del: "Номер удален из стоплиста."
  // stoplist/get: "Запрос обработан. На последующих строчках будут идти номера телефонов, указанных в стоплисте в формате номер;примечание."
  100 : "Сообщение находится в нашей очереди", 
  101 : "Сообщение передается оператору",
  102 : "Сообщение отправлено (в пути)",
  103 : "Сообщение доставлено",
  104 : "Не может быть доставлено: время жизни истекло",
  105 : "Не может быть доставлено: удалено оператором",
  106 : "Не может быть доставлено: сбой в телефоне",
  107 : "Не может быть доставлено: неизвестная причина",
  108 : "Не может быть доставлено: отклонено",
  200 : "Неправильный api_id",  
  201 : "Не хватает средств на лицевом счету",
  202 : "Неправильно указан получатель",
  203 : "Нет текста сообщения",
  204 : "Имя отправителя не согласовано с администрацией",
  205 : "Сообщение слишком длинное (превышает 8 СМС)",
  206 : "Будет превышен или уже превышен дневной лимит на отправку сообщений",
  207 : "На этот номер нельзя отправлять сообщения",
  208 : "Параметр time указан неправильно",
  209 : "Вы добавили этот номер (или один из номеров) в стоп-лист",
  210 : "Используется GET, где необходимо использовать POST",
  211 : "Метод не найден",
  220 : "Сервис временно недоступен, попробуйте чуть позже.",
  300 : "Неправильный token (возможно истек срок действия, либо ваш IP изменился)",
  301 : "Неправильный пароль, либо пользователь не найден",
  302 : "Пользователь авторизован, но аккаунт не подтвержден (пользователь не ввел код, присланный в регистрационной смс)"
};