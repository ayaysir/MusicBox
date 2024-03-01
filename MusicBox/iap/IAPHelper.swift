import StoreKit

public struct InAppProducts {
    private init() {}
    
    /// 앱 스토어 커넥트에 등록된 IAP의 제품 ID들의 리스트입니다.
    public static let productIDs = [
        "com.yoonbumtae.DiffuserStick.IAP.removeAds1"
    ]
    
    private static let productIdentifiers: Set<ProductIdentifier> = Set(productIDs)
    public static let helper = IAPHelper(productIds: InAppProducts.productIdentifiers)
}

public typealias ProductIdentifier = String
public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> Void

extension Notification.Name {
    static let IAPHelperPurchaseNotification = Notification.Name("IAPHelperPurchaseNotification")
    static let IAPHelperErrorNotification = Notification.Name("IAPHelperErrorNotification")
}

open class IAPHelper: NSObject {
    private let productIdentifiers: Set<ProductIdentifier>
    private var purchasedProductIdentifiers: Set<ProductIdentifier> = []
    private var productsRequest: SKProductsRequest?
    private var productsRequestCompletionHandler: ProductsRequestCompletionHandler?
    
    public init(productIds: Set<ProductIdentifier>) {
        productIdentifiers = productIds
        
        for productIdentifier in productIds {
            let purchased = UserDefaults.standard.bool(forKey: productIdentifier)
            
            if purchased {
                purchasedProductIdentifiers.insert(productIdentifier)
                print("IAP: (Maybe previously purchased): \(productIdentifier)")
            } else {
                print("IAP: (Maybe not purchased): \(productIdentifier)")
            }
        }
        
        super.init()
        SKPaymentQueue.default().add(self) // App Store와 지불정보를 동기화하기 위한 Observer 추가
    }
}

extension IAPHelper {
    /// 앱스토어에서 등록된 인앱결제 상품들을 가져옵니다.
    public func inquireProductsRequest(_ completionHandler: @escaping ProductsRequestCompletionHandler) {
        productsRequest?.cancel()
        productsRequestCompletionHandler = completionHandler
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest!.delegate = self
        productsRequest!.start()
    }
    
    /// 인앱결제 상품을 구입합니다.
    public func buyProduct(_ product: SKProduct) {
        print("IAP Buying: \(product.productIdentifier)...")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    /// IAP 제품을 구매했는지 판별합니다.
    /// - `purchasedProductIdentifiers`: IAPHelper 초기화시 또는 실제 제품을 구입했을 때 추가됩니다.
    public func isProductPurchased(_ productIdentifier: ProductIdentifier) -> Bool {
        return purchasedProductIdentifiers.contains(productIdentifier)
    }
    
    /// 제품을 구입할 권한이 있는지
    /// - 계정을 관리하는 자가 별도로 있는 경우 제품 구매 권한이 없을 수도 있습니다.
    public class func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    /// 구입내역을 복원합니다.
    public func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

extension IAPHelper: SKProductsRequestDelegate {
    /*
     SKProductsRequestDelegate에서 구현을 요구하는 메서드로 IAP 제품 리스트 목록을 성공적으로 받아왔을 때 실행됩니다.
     */
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("IAP: Loaded list of products...")
        let products = response.products
        productsRequestCompletionHandler?(true, products)
        clearRequestAndHandler()
        
        for p in products {
            print("IAP - Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
        }
    }
    
    /*
     SKProductsRequestDelegate에서 구현을 요구하는 메서드로 IAP 제품 리스트 목록을 가져오는데 실패했을 때 실행됩니다.
     */
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        print("IAP - Failed to load list of products.")
        print("IAP - Error: \(error.localizedDescription)")
        productsRequestCompletionHandler?(false, nil)
        clearRequestAndHandler()
    }
    
    private func clearRequestAndHandler() {
        productsRequest = nil
        productsRequestCompletionHandler = nil
    }
}

extension IAPHelper: SKPaymentTransactionObserver {
    /// paymentQueue(_:updatedTransactions:)는 프로토콜에서 실제로 필요한 유일한 방법입니다.
    /// - 하나 이상의 트랜잭션 상태가 변경될 때 호출됩니다.
    /// - 이 메서드는 업데이트된 트랜잭션 배열에서 각 트랜잭션의 상태를 평가하고 관련 도우미 메서드인 `complete(transaction:)`, `restore(transaction:)` 또는 `fail(transaction:)`을 호출합니다.
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
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
                print("IAP Transaction: Deferred")
                break
            case .purchasing:
                print("IAP Transaction: Purchasing")
                break
            @unknown default:
                break
            }
        }
    }
    
    /// 구입 완료한 경우 트랜잭션 처리
    private func complete(transaction: SKPaymentTransaction) {
        print("IAP Transaction Purchase: complete...")
        deliverPurchaseNotificationFor(identifier: transaction.payment.productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    /// 복원 성공한 경우 트랜잭션 처리
    private func restore(transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
        
        print("IAP Transaction: restore... \(productIdentifier)")
        deliverPurchaseNotificationFor(identifier: productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    /// 구매 실패
    private func fail(transaction: SKPaymentTransaction) {
        print("IAP Transaction Purchase: fail...")
        
        if let transactionError = transaction.error as NSError? {
            print("IAP Transaction Error: \(transactionError.localizedDescription)")
        }
        
        deliverPurchaseErrorNotification()
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    /// 구매한 인앱 상품 키를 UserDefaults로 로컬에 저장
    /// - 실제로 구입 성공/복원된 경우에만 실행된다.
    private func deliverPurchaseNotificationFor(identifier: String?) {
        print(#function, identifier ?? "")
        guard let identifier = identifier else { return }

        purchasedProductIdentifiers.insert(identifier)
        UserDefaults.standard.set(true, forKey: identifier)
        NotificationCenter.default.post(name: .IAPHelperPurchaseNotification, object: identifier)
    }
    
    /// 제품 구매 실패시 Notification을 보냅니다.
    /// - Notification의 이름은 `.IAPHelperErrorNotification`입니다.
    private func deliverPurchaseErrorNotification() {
        NotificationCenter.default.post(name: .IAPHelperErrorNotification, object: nil)
    }
}

extension IAPHelper {
    /// 구매이력 영수증 가져오기 - 검증용
    public func getReceiptData() -> String? {
        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
            FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {
            do {
                let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
                let receiptString = receiptData.base64EncodedString(options: [])
                return receiptString
            }
            catch {
                print("IAP - Couldn't read receipt data with error: " + error.localizedDescription)
                return nil
            }
        }
        
        return nil
    }
}

extension SKProduct {
    /// 각국 통화 포맷 처리기
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

    /// IAP 제품이 공짜인지 여부
    var isFree: Bool {
        price == 0.00
    }

    /// 현지화된 가격 정보
    /// - 통화 기호가 같이 표시됩니다.
    var localizedPrice: String? {
        guard !isFree else {
            return nil
        }
        
        let formatter = SKProduct.formatter
        formatter.locale = priceLocale

        return formatter.string(from: price)
    }
}

