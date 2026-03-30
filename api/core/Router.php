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
        // GET ile gelen 'url' parametresini kontrol et (.htaccess'ten gelen yönlendirme)
        if (isset($_GET['url'])) {
            $requestUri = '/' . rtrim($_GET['url'], '/');
        } else {
            // Soru işaretinden (query string) sonrasını at
            if (($pos = strpos($requestUri, '?')) !== false) {
                $requestUri = substr($requestUri, 0, $pos);
            }

            // Eğer URL'nin başında /api varsa (Flutter eski ayardan atıyorsa) onu temizle
            $basePath = '/api'; 
            if (strpos($requestUri, $basePath) === 0) {
                $requestUri = substr($requestUri, strlen($basePath));
            }

            // Eğer XAMPP gibi bir alt klasör üzerinden çalışıyorsa "/wefriend/api" veya "/wefriend" de gelebilir.
            $basePath2 = '/wefriend/api';
            if (strpos($requestUri, $basePath2) === 0) {
                $requestUri = substr($requestUri, strlen($basePath2));
            }
            
            $basePath3 = '/wefriend';
            if (strpos($requestUri, $basePath3) === 0) {
                $requestUri = substr($requestUri, strlen($basePath3));
            }
        }

        // Olası bir çift slash durumunu veya boşluğu temizle
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