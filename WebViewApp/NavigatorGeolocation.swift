import CoreLocation
import WebKit

class NavigatorGeolocation: NSObject, WKScriptMessageHandler, CLLocationManagerDelegate {

    var locationManager = CLLocationManager()
    var listenersCount = 0
    var webView: WKWebView!

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func setWebView(webView: WKWebView) {
        webView.configuration.userContentController.add(self, name: "listenerAdded")
        webView.configuration.userContentController.add(self, name: "listenerRemoved")
        self.webView = webView
    }

    func locationServicesIsEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }

    func authorizationStatusNeedRequest(status: CLAuthorizationStatus) -> Bool {
        (status == .notDetermined) ? true : false
    }

    func authorizationStatusIsGranted(status: CLAuthorizationStatus) -> Bool {
        (status == .authorizedAlways || status == .authorizedWhenInUse) ? true : false
    }

    func authorizationStatusIsDenied(status: CLAuthorizationStatus) -> Bool {
        (status == .restricted || status == .denied) ? true : false
    }

    func onLocationServicesIsDisabled() {
        webView.evaluateJavaScript("navigator.geolocation.helper.error(2, 'Location services disabled');")
    }

    func onAuthorizationStatusNeedRequest() {
        locationManager.requestWhenInUseAuthorization()
    }

    func onAuthorizationStatusIsGranted() {
        locationManager.startUpdatingLocation()
    }

    func onAuthorizationStatusIsDenied() {
        webView.evaluateJavaScript("navigator.geolocation.helper.error(1, 'App does not have location permission');")
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "listenerAdded" {
            listenersCount += 1

            if !locationServicesIsEnabled() {
                onLocationServicesIsDisabled()
            } else if authorizationStatusIsDenied(status: locationManager.authorizationStatus) {
                onAuthorizationStatusIsDenied()
            } else if authorizationStatusNeedRequest(status: locationManager.authorizationStatus) {
                onAuthorizationStatusNeedRequest()
            } else if authorizationStatusIsGranted(status: locationManager.authorizationStatus) {
                onAuthorizationStatusIsGranted()
            }
        } else if message.name == "listenerRemoved" {
            listenersCount -= 1

            // no listener left in web view to wait for position
            if listenersCount == 0 {
                locationManager.stopUpdatingLocation()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // didChangeAuthorization is also called at app startup, so this condition checks listeners
        // count before doing anything otherwise app will start location service without reason
        if listenersCount > 0 {
            if authorizationStatusIsDenied(status: status) {
                onAuthorizationStatusIsDenied()
            } else if authorizationStatusIsGranted(status: status) {
                onAuthorizationStatusIsGranted()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            webView.evaluateJavaScript("navigator.geolocation.helper.success('\(location.timestamp)', \(location.coordinate.latitude), \(location.coordinate.longitude), \(location.altitude), \(location.horizontalAccuracy), \(location.verticalAccuracy), \(location.course), \(location.speed));")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        webView.evaluateJavaScript("navigator.geolocation.helper.error(2, 'Failed to get position (\(error.localizedDescription))');")
    }

    // swiftlint:disable:next function_body_length
    func getJavaScriptToEvaluate() -> String {
        let javaScriptToEvaluate = """
            // management for success and error listeners and its calling
            navigator.geolocation.helper = {
                listeners: {},
                noop: function() {},
                id: function() {
                    var min = 1, max = 1000;
                    return Math.floor(Math.random() * (max - min + 1)) + min;
                },
                clear: function(isError) {
                    for (var id in this.listeners) {
                        if (isError || this.listeners[id].onetime) {
                            navigator.geolocation.clearWatch(id);
                        }
                    }
                },
                success: function(timestamp, latitude, longitude, altitude, accuracy, altitudeAccuracy, heading, speed) {
                    var position = {
                        timestamp: new Date(timestamp).getTime() || new Date().getTime(), // safari can not parse date format returned by swift e.g. 2019-12-27 15:46:59 +0000 (fallback used because we trust that safari will learn it in future because chrome knows that format)
                        coords: {
                            latitude: latitude,
                            longitude: longitude,
                            altitude: altitude,
                            accuracy: accuracy,
                            altitudeAccuracy: altitudeAccuracy,
                            heading: (heading > 0) ? heading : null,
                            speed: (speed > 0) ? speed : null
                        }
                    };
                    for (var id in this.listeners) {
                        this.listeners[id].success(position);
                    }
                    this.clear(false);
                },
                error: function(code, message) {
                    var error = {
                        PERMISSION_DENIED: 1,
                        POSITION_UNAVAILABLE: 2,
                        TIMEOUT: 3,
                        code: code,
                        message: message
                    };
                    for (var id in this.listeners) {
                        this.listeners[id].error(error);
                    }
                    this.clear(true);
                }
            };

            // @override getCurrentPosition()
            navigator.geolocation.getCurrentPosition = function(success, error, options) {
                var id = this.helper.id();
                this.helper.listeners[id] = { onetime: true, success: success || this.noop, error: error || this.noop };
                window.webkit.messageHandlers.listenerAdded.postMessage("");
            };

            // @override watchPosition()
            navigator.geolocation.watchPosition = function(success, error, options) {
                var id = this.helper.id();
                this.helper.listeners[id] = { onetime: false, success: success || this.noop, error: error || this.noop };
                window.webkit.messageHandlers.listenerAdded.postMessage("");
                return id;
            };

            // @override clearWatch()
            navigator.geolocation.clearWatch = function(id) {
                var idExists = (this.helper.listeners[id]) ? true : false;
                if (idExists) {
                    this.helper.listeners[id] = null;
                    delete this.helper.listeners[id];
                    window.webkit.messageHandlers.listenerRemoved.postMessage("");
                }
            };
        """

        return javaScriptToEvaluate
    }

}
