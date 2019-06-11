//
//  ViewController.swift
//  UIHostApp
//
//  Created by Niraj Chauhan on 5/5/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import UIKit
import PaymentSDK
import PassKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SettingsDelegate {
    
    static var currency:String = "USD"
    static var email:String = "test@gmail.com"
    static var cartTotal = 0
    
    @IBOutlet weak var tableView: UITableView!
    
    private var products:[Product] = []
    
    @IBOutlet weak var totalLabel: UILabel!
    
    @IBOutlet weak var totalTaxLabel: UILabel!
    
    @IBOutlet weak var grandTotalLabel: UILabel!
    
    @IBOutlet weak var footerStackView: UIStackView!
    
    private var cardPaymentButton : UIButton?
    private var applePayButton : UIButton?
    private var paymentDelegate : PaymentDelegate?
    private var applePayDelegate : ApplePayDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerTableViewCells()
        loadProducts()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableView.automaticDimension
        tableView.alwaysBounceVertical = false //Disable scroll
        
        self.renderButtons()
        PaymentSDKHandler.configureSDK()

        self.paymentDelegate = PaymentSDKDelegate()
        self.applePayDelegate = ApplePaySDKDelegate()
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100;
    }
    
    private func loadProducts(){
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "products_en", withExtension: "json"),
            let jsonData = try? Data(contentsOf: url, options: Data.ReadingOptions.mappedIfSafe)
            else {
                return
        }
        
        do {
            let decoder = JSONDecoder()
            products = try decoder.decode([Product].self, from: jsonData)
            self.tableView.reloadData()
        } catch let err {
            print("Err", err)
        }
    }
    
    //Table View
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CartItemTableViewCell", for: indexPath) as! CartItemTableViewCell
        let product = products[indexPath.row]
        
        let price = product.prices.filter({(price:Product.Price) in return price.currency == ViewController.currency}).first
        var productPrice = 0.0;
        if let p = price {
            productPrice = p.total/100
        }
        
        cell.productImage.image = UIImage(named: product.info.image)
        cell.productTitle.text = product.info.name
        cell.productQuantity.text = "Quantity: \(product.quantity)"
        cell.productPrice.text = "Price: \(productPrice) \(ViewController.currency)"
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        cell.stepper.tag = indexPath.row
        cell.stepper.value = Double(product.quantity)
        cell.stepper.addTarget(self, action: #selector(ViewController.stepperValueChanged(_:)), for: .valueChanged)
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let lastVisibleIndexPath = tableView.indexPathsForVisibleRows?.last {
            if indexPath == lastVisibleIndexPath {
                updateTotal()
            }
        }
    }
    
    // Table view end
    @objc func stepperValueChanged(_ sender: UIStepper) {
        products[sender.tag].quantity = sender.value
        self.tableView.reloadData()
    }
    
    private func updateTotal(){
        let total = products.reduce(0.0) { (res, p) -> Double in
            let priceObjOptional = p.prices.filter({(price:Product.Price) in return price.currency == ViewController.currency}).first
            guard let priceTotal = priceObjOptional?.total else {
                return res
            }
            return res + (p.quantity * priceTotal)
        }
        let totalTax = products.reduce(0.0) { (res, p) -> Double in
            let priceObjOptional = p.prices.filter({(price:Product.Price) in return price.currency == ViewController.currency}).first
            guard let priceTotal = priceObjOptional?.tax else {
                return res
            }
            return res + (p.quantity * priceTotal)
        }
        totalLabel.text = "Total: \(total/100)"
        totalTaxLabel.text = "Tax: \(totalTax/100)"
        ViewController.cartTotal = Int(total + totalTax)
        grandTotalLabel.text = "Grand total: \((ViewController.cartTotal)/100)"
    }
    
    private func registerTableViewCells(){
        let cartItemCell = UINib(nibName: "CartItemTableViewCell", bundle: nil)
        self.tableView.register(cartItemCell, forCellReuseIdentifier: "CartItemTableViewCell")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let settingsViewController = segue.destination as! SettingsViewController
        settingsViewController.currency = ViewController.currency
        settingsViewController.email = ViewController.email
        settingsViewController.settingsDelegate = self
    }
    
    func didEmailChange(_ email: String) {
        print(email)
        ViewController.email = email
        self.tableView.reloadData()
    }
    
    func didCurrencyChange(_ currency: String) {
        ViewController.currency = currency
        self.tableView.reloadData()
    }
    
    private func getApplePayButton() -> UIButton
    {
        let button = PKPaymentButton(paymentButtonType: .buy , paymentButtonStyle: .black)
        button.addTarget(self, action: #selector(payWithApplePayAction), for: .touchUpInside)
        return button
    }
    
    @objc private func payWithApplePayAction(sender: UIButton?)
    {
        let instance = PaymentSDKHandler.sharedInstance
        instance.showApplePayPaymentView(paymentDelegate: self.paymentDelegate, applePayDelegate: self.applePayDelegate, overParent: self, request: getApplePayRequest(), items: getAppleSummaryItems()){
            print("Showing apple payment view!")
        }
    }
    
    private func getCardPayButton() -> UIButton
    {
        let button = UIButton(type: .roundedRect)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red:0.89, green:0.89, blue:0.89, alpha:1.0).cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        
        button.setTitle("Pay by card", for: .normal)
        button.addTarget(self, action: #selector(payByCardAction), for: .touchUpInside)
        return button
    }
    
    @objc private func payByCardAction(sender: UIButton?)
    {
        let instance = PaymentSDKHandler.sharedInstance
        instance.showCardPaymentView(delegate: self.paymentDelegate, overParent: self){
            print("Showing card payment view!")
        }
    }
    
    private func renderButtons() {
        // card
        self.cardPaymentButton = self.getCardPayButton()
        let cardStackView = getStackView()
        cardStackView.addArrangedSubview(self.cardPaymentButton!)
        footerStackView.addArrangedSubview(cardStackView)
        
        //Apple pay
        self.applePayButton = self.getApplePayButton()
        let applePayStackView = getStackView()
        applePayStackView.addArrangedSubview(self.applePayButton!)
        footerStackView.addArrangedSubview(applePayStackView)
    }
    
    private func getStackView() -> UIStackView {
        let stackView           = UIStackView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        stackView.axis          = .vertical
        stackView.distribution  = .fill
        stackView.alignment     = .center
        stackView.spacing       = 30.0
        return stackView
    }
    
    private func getAppleSummaryItems() -> [PKPaymentSummaryItem]{
        var total = NSDecimalNumber(mantissa: UInt64(0), exponent: -2, isNegative: false)
        var items = self.products
            .filter({ (product) -> Bool in
                return product.quantity > 0
            })
            .map { (product) -> PKPaymentSummaryItem in
            let price = product.prices.filter({(price:Product.Price) in return price.currency == ViewController.currency}).first
            var productPrice = 0.0;
            if let p = price {
                productPrice = p.total * product.quantity
            }
            let decimal = NSDecimalNumber(mantissa: UInt64(productPrice), exponent: -2, isNegative: false)
            total = decimal.adding(total)
            return PKPaymentSummaryItem(label: product.info.name,amount: decimal )
        }
        items.append(PKPaymentSummaryItem(label: "Total", amount: total ))
        return items
    }
    
    private func getApplePayRequest() -> PKPaymentRequest{
        let request = PKPaymentRequest()
        request.countryCode = "AE"
        request.currencyCode = ViewController.currency
        request.requiredShippingContactFields = [.postalAddress, .emailAddress, .phoneNumber]
        request.merchantCapabilities = [.capabilityDebit, .capabilityCredit, .capability3DS]

        return request
    }
    
}

