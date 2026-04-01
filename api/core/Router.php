<?php

class Router {
    private $routes = [];

    // Yeni bir rota (endpoint) ekler
    public function add($method, $uri, $controller, $action) {
        $this->routes[] = [
            'method' => $method,
            'uri' => $uri,
            'controller' => $controller,
            'action' => $action
        ];
    }

    // Gelen isteği doğru controller ve metoda yönlendirir
    public function dispatch($requestMethod, $requestUri) {
        $originalUri = $requestUri; // Hata mesajı için saklayalım

        // Önce query string'i atalım
        if (($pos = strpos($requestUri, '?')) !== false) {
            $requestUri = substr($requestUri, 0, $pos);
        }

        // XAMPP veya alt klasör isimlerini sırayla temizle (en uzundan en kısaya)
        $prefixesToRemove = [
            '/wefriend/api',
            '/wefriend',
            '/api'
        ];

        foreach ($prefixesToRemove as $prefix) {
            if (strpos($requestUri, $prefix) === 0) {
                $requestUri = substr($requestUri, strlen($prefix));
                break; // İlk eşleşeni sildiğinde dur, aksi halde fazla kırpabilir
            }
        }

        // .htaccess'ten gelen 'url' parametresini kullanmayı tercih edebiliriz, ama 
        // bazen sunucu ayarlarından dolayı $_GET['url'] boş gelebilir veya eksik olabilir.
        // Bu yüzden REQUEST_URI'yi kullanıp prefixleri temizlemek en garantisidir.
        // Ancak .htaccess 'url' parametresi verdiyse, requestUri'yi ona göre de ezebiliriz.
        if (isset($_GET['url']) && !empty($_GET['url'])) {
            $urlParam = '/' . rtrim($_GET['url'], '/');
            // Eğer $urlParam, zaten temizlediğimiz $requestUri ile uyuşmuyorsa, .htaccess'ten geleni kullan
            // Örneğin XAMPP'da $_GET['url'] bazen "wefriend/api/auth/login" olarak tam yol gelir
            // Bu yüzden $_GET['url'] içinde de aynı prefix temizliğini yapalım
            foreach ($prefixesToRemove as $prefix) {
                $prefixWithoutSlash = ltrim($prefix, '/');
                if (strpos($urlParam, '/' . $prefixWithoutSlash) === 0) {
                    $urlParam = substr($urlParam, strlen('/' . $prefixWithoutSlash));
                    break;
                }
            }
            $requestUri = $urlParam;
        }

        // URL sonundaki slash'i temizle (Eğer sadece '/' değilse)
        if ($requestUri !== '/') {
            $requestUri = rtrim($requestUri, '/');
        }

        // Boşluk kalırsa root kabul et
        if ($requestUri == '' || $requestUri == '/') {
            $requestUri = '/';
        }

        // Endpoint eşleştirmesi
        foreach ($this->routes as $route) {
            if ($route['method'] == $requestMethod && $route['uri'] == $requestUri) {
                $controllerName = $route['controller'];
                $actionName = $route['action'];

                // Controller sınıfını başlat
                if (class_exists($controllerName)) {
                    $controller = new $controllerName();
                    
                    if (method_exists($controller, $actionName)) {
                        // İlgili metodu çağır
                        $controller->$actionName();
                        return;
                    } else {
                        Response::json(500, "Sistem Hatası: Metod ($actionName) bulunamadı.");
                    }
                } else {
                    Response::json(500, "Sistem Hatası: Controller ($controllerName) bulunamadı.");
                }
            }
        }

        // Hiçbir rota eşleşmezse 404 dön
        Response::json(404, "Endpoint bulunamadı. Method: " . $requestMethod . " | Algılanan URI: " . $requestUri . " | Raw GET URL: " . (isset($_GET['url']) ? $_GET['url'] : 'YOK'));
    }
}
?>