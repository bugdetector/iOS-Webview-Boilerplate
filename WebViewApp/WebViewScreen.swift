//
//  WebViewScreen.swift
//  Created by Murat Baki Yücel on 26/01/24.
//



import SwiftUI

struct WebViewScreen: View {
    
    var url: String? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    WebView(url: URL(string: url != nil ? url! : Constants.BASE_URL))
                }
            }
        }
    }
}
