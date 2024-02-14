//
//  WebViewScreen.swift
//  Created by Atif Qamar on 26/01/24.
//



import SwiftUI

struct WebViewScreen: View {
    
    @ObservedObject var viewModel = WebViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    WebView(url: URL(string: "https://www.example.com"), viewModel: viewModel)
                }
            }
        }
    }
}
