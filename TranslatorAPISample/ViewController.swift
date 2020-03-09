//
//  ViewController.swift
//  TranslatorAPISample
//
//  Created by 飛田 由加 on 2020/03/05.
//  Copyright © 2020 atrasc. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController {
    
    @IBOutlet weak var textToTranslate: UITextView! //翻訳前テキスト
    @IBOutlet weak var translatedText: UITextView!  //翻訳後テキスト
    
    let jsonEncoder = JSONEncoder()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func getTranslation(_ sender: UIButton) {
        
        //https://docs.microsoft.com/ja-jp/azure/cognitive-services/translator/reference/v3-0-translate
        
        let selectedFromLangCode = "en" // 翻訳前言語
        let selectedToLangCode = "ja"   // 翻訳後言語
        
        struct encodeText: Codable {
            var text = String()
        }
        
        let azureKey = "139a7eb6048642989da79f6f15d85c16" // サブスクリプションキー key1
        let contentType = "application/json" // コンテンツタイプ
        let traceID = "A14C9DB9-0DED-48D7-8BBE-C517A1A8DBB0" // GUID（グローバル一意識別子、UUID）
//        let host = "dev.microsofttranslator.com"
        let apiURL = "https://dev.microsofttranslator.com/translate?api-version=3.0&from=" + selectedFromLangCode + "&to=" + selectedToLangCode //fromは省略可能
        
        let text2Translate = textToTranslate.text
        var encodeTextSingle = encodeText()
        var toTranslate = [encodeText]()
        
        encodeTextSingle.text = text2Translate!
        toTranslate.append(encodeTextSingle)
        
        let jsonToTranslate = try? jsonEncoder.encode(toTranslate)
        let url = URL(string: apiURL)
        var request = URLRequest(url: url!)

        request.httpMethod = "POST"
        request.addValue(azureKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key") // 認証ヘッダー（必須）
        request.addValue(contentType, forHTTPHeaderField: "Content-Type") // コンテンツタイプ（必須）
        request.addValue(traceID, forHTTPHeaderField: "X-ClientTraceID") //要求を一意に識別するGUID（クエリ文字列内に含める場合省略可能）
//        request.addValue(host, forHTTPHeaderField: "Host")
        request.addValue(String(describing: jsonToTranslate?.count), forHTTPHeaderField: "Content-Length") // 要求本文の長さ(1)（必須）
        request.httpBody = jsonToTranslate
        
        let config = URLSessionConfiguration.default
        let session =  URLSession(configuration: config)
        
        let task = session.dataTask(with: request) { (responseData, response, responseError) in
            
            if responseError != nil {
                print("this is the error ", responseError!)
                
                let alert = UIAlertController(title: "Could not connect to service", message: "Please check your network connection and try again", preferredStyle: .actionSheet)
                
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                
                self.present(alert, animated: true)
            }
            print("*****")
            self.parseJson(jsonData: responseData!)
        }
        task.resume()
    }
    
    func parseJson(jsonData: Data) {
        
        //*****TRANSLATION RETURNED DATA*****
        struct ReturnedJson: Codable {
            var translations: [TranslatedStrings]
        }
        struct TranslatedStrings: Codable {
            var text: String
            var to: String
        }
        
        let jsonDecoder = JSONDecoder()
        let langTranslations = try? jsonDecoder.decode(Array<ReturnedJson>.self, from: jsonData)
        let numberOfTranslations = langTranslations!.count - 1
        print(langTranslations!.count)
        
        //Put response on main thread to update UI
        DispatchQueue.main.async {
            self.translatedText.text =  langTranslations![0].translations[numberOfTranslations].text
        }
    }
}
