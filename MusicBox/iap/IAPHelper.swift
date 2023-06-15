//
//  IAPHelper.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/23.
//

import StoreKit

public typealias ProductIdentifier = String
public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> Void

extension Notification.Name {
    static let IAPHelperPurchaseNotification = Notification.Name("IAPHelperPurchaseNotification")
}

open class IAPHelper: NSObject {
    
    private let productIdentifiers: Set<ProductIdentifier>
    private var purchasedProductIdentifiers: Set<ProductIdentifier> = []
    private var productsRequest: SKProductsRequest?
    private var productsRequestCompletionHandler: ProductsRequestCompletionHandler?
    
    init(productIds: Set<ProductIdentifier>) {
        productIdentifiers = productIds
        for productIdentifier in productIds {
            let purchased = UserDefaults.standard.bool(forKey: productIdentifier)
            if purchased {
                purchasedProductIdentifiers.insert(productIdentifier)
                print("Previously purchased: \(productIdentifier)")
            } else {
                print("Not purchased: \(productIdentifier)")
            }
        }
        super.init()
        
        // func add(_ observer: SKPaymentTransactionObserver)
        SKPaymentQueue.default().add(self)
    }

}

// MARK: - StoreKit API

extension IAPHelper {
    
    /// 이 코드는 나중에 실행할 수 있도록 사용자의 완료 핸들러를 저장합니다. 그런 다음 SKProductsRequest 개체를 통해 Apple에 대한 요청을 생성하고 시작합니다.
    public func requestProducts(_ completionHandler: @escaping ProductsRequestCompletionHandler) {
        productsRequest?.cancel()
        productsRequestCompletionHandler = completionHandler
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest!.delegate = self
        productsRequest!.start()
    }
    
    /// 이것은 SKProduct(Apple 서버에서 검색)를 사용하여 지불 객체를 생성하여 지불 대기열에 추가합니다. 이 코드는 default()라는 싱글톤 SKPaymentQueue 객체를 활용합니다.
    public func buyProduct(_ product: SKProduct) {
        print("Buying \(product.productIdentifier)...")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func isProductPurchased(_ productIdentifier: ProductIdentifier) -> Bool {
        return purchasedProductIdentifiers.contains(productIdentifier)
    }
    
    public class func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    public func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

// MARK: - SKProductsRequestDelegate

/// 이 확장은 SKProductsRequestDelegate 프로토콜에 필요한 두 가지 방법을 구현하여 Apple 서버에서 제품 목록, 제목, 설명 및 가격을 가져오는 데 사용됩니다.
extension IAPHelper: SKProductsRequestDelegate {
    
    /// 목록이 성공적으로 검색되면 productsRequest(_:didReceive:)가 호출됩니다. SKProduct 개체의 배열을 수신하고 이전에 저장된 completion handler에 전달합니다. 핸들러는 새 데이터로 테이블을 다시 로드합니다. 문제가 발생하면 request(_:didFailWithError:)가 호출됩니다. 두 경우 모두 요청이 완료되면 요청과 완료 핸들러가 모두 clearRequestAndHandler()로 지워집니다.
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("Loaded list of products...")
        let products = response.products
        productsRequestCompletionHandler?(true, products)
        clearRequestAndHandler()
        
        for p in products {
            print("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
        }
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Failed to load list of products.")
        print("Error: \(error.localizedDescription)")
        productsRequestCompletionHandler?(false, nil)
        clearRequestAndHandler()
    }
    
    private func clearRequestAndHandler() {
        productsRequest = nil
        productsRequestCompletionHandler = nil
    }
}

// MARK: - SKPaymentTransactionObserver

extension IAPHelper: SKPaymentTransactionObserver {
    
    /// paymentQueue(_:updatedTransactions:)는 프로토콜에서 실제로 필요한 유일한 방법입니다. 하나 이상의 트랜잭션 상태가 변경될 때 호출됩니다. 이 메서드는 업데이트된 트랜잭션 배열에서 각 트랜잭션의 상태를 평가하고 관련 도우미 메서드인 complete(transaction:), restore(transaction:) 또는 fail(transaction:)을 호출합니다.
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchased:
                complete(transaction: transaction)
                break
            case .failed:
                fail(transaction: transaction)
                break
            case .restored:
                restore(transaction: transaction)
                break
            case .deferred:
                break
            case .purchasing:
                break
            @unknown default:
                fatalError("unknown")
            }
        }
    }
    
    private func complete(transaction: SKPaymentTransaction) {
        print("complete...")
        deliverPurchaseNotificationFor(identifier: transaction.payment.productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func restore(transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
        
        print("restore... \(productIdentifier)")
        deliverPurchaseNotificationFor(identifier: productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func fail(transaction: SKPaymentTransaction) {
        print("fail...")
        if let transactionError = transaction.error as NSError?,
           let localizedDescription = transaction.error?.localizedDescription,
           transactionError.code != SKError.paymentCancelled.rawValue {
            print("Transaction Error: \(localizedDescription)")
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func deliverPurchaseNotificationFor(identifier: String?) {
        guard let identifier = identifier else { return }
        
        purchasedProductIdentifiers.insert(identifier)
        UserDefaults.standard.set(true, forKey: identifier)
        NotificationCenter.default.post(name: .IAPHelperPurchaseNotification, object: identifier)
    }
}

