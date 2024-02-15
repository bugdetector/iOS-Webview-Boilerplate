//
//  WebViewScreen.swift
//  Created by Murat Baki Yücel on 26/01/24.
//



import SwiftUI

struct WebViewScreen: View {
    
    @ObservedObject var viewModel = WebViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    WebView(url: URL(string: Constants.BASE_URL), viewModel: viewModel)
                }
            }
        }
    }
}
