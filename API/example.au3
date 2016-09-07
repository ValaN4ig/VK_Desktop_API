#include <VK_Desktop_API.au3>
;~ -------------------------------------------------------------------------------
;~ Name: Example VK_Desktop_API
;~ Author: Valan4ig
;~ NickName: ---Zak---
;~ Version: 1.4.1.1 (1.4-b1)
;~ Author URI: http://vk.com/id859000
;~ -------------------------------------------------------------------------------

   $VKAPI_login = 'YouEmailOrPhone'
   $VKAPI_pass 	= 'YouPassword'

;~ Первоначальная авторизация пользователя с указанием ID standalone-клиента по-умолчанию (2987875), а так же прав доступа (136232095)
_vAPI_OAuth2($VKAPI_login, $VKAPI_pass)
;~ Получает настройки текущего пользователя в данном приложении.
_vAPI_GETMethod("account.getAppPermissions")
   _ArrayDisplay($aFun, '$aFun')
;~ Возвращает список аудиозаписей пользователя. Количество аудиозаписей = 20
_vAPI_GETMethod("audio.get", "owner_id=--21354&count=20")
      _ArrayDisplay($aFun, '$aFun')
;~ Возвращает информацию о сообществе идентификатор или короткое имя сообщества равному sosimc (официальнная группа ВКонтакте группировке 'Ленинград")
_vAPI_GETMethod("groups.getById", "group_id=sosimc")
   _ArrayDisplay($aFun, '$aFun')
;~ Возвращает список 5 стран.
_vAPI_GETMethod("database.getCountries", "need_all=1&count=5")
   _ArrayDisplay($aFun, '$aFun')
;~ Возвращает 5 приложений, доступных для пользователей сайта через каталог приложений.
_vAPI_GETMethod("apps.getCatalog", "count=5")
   _ArrayDisplay($aFun, '$aFun')


