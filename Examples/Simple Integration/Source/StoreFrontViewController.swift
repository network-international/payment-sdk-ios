//
//  StoreFrontViewController.swift
//  Simple Integration
//
//  Created by Johnny Peter on 22/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import UIKit
import NISdk

class StoreFrontViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, CardPaymentDelegate {
    
    var collectionView: UICollectionView?
    let payButton = UIButton(type: .system)
    let pets = ["🦁", "🐅", "🐆", "🦓", "🦏"]
    var total: Int = 0 {
        didSet { showHidePayButton() }
    }
    
    @objc func paymentDidComplete(with status: PaymentStatus) {
        
    }
    
    @objc func authorizationDidComplete(with status: AuthorizationStatus) {
        
    }
    
    @objc func payButtonTapped() {
        let orderCreationViewController = OrderCreationViewController(paymentAmount: total, and: self)
        self.present(orderCreationViewController, animated: true, completion: nil)
    }
    
    func setupPayButton() {
        payButton.backgroundColor = .black
        payButton.setTitleColor(.white, for: .normal)
        payButton.setTitle("Pay", for: .normal)
        payButton.addTarget(self, action: #selector(payButtonTapped), for: .touchUpInside)
        
        navigationController?.view.addSubview(payButton)
        setPayButtonConstraints()
    }
    
    func setPayButtonConstraints() {
        if let parentView = navigationController?.view {
            payButton.translatesAutoresizingMaskIntoConstraints = false
            payButton.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 20).isActive = true
            payButton.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -20).isActive = true
            payButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
            payButton.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -50).isActive = true
            payButton.isHidden = true
//            payButton.centerYAnchor.constraint(equalTo: parentView.centerYAnchor).isActive = true
        }
    }
    
    func showHidePayButton() {
        if(total > 0) {
            payButton.isHidden = false
            payButton.setTitle("Pay AED \(total)", for: .normal)
        } else {
            payButton.isHidden = true
        }
    }
    
    func add(amount: Int) {
        total += amount
    }
    
    func remove(amount: Int) {
        total -= amount
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPayButton()
        title = "Zoomoji Store"
        let indexPath = IndexPath(item: pets.count, section: 0)
        self.collectionView?.insertItems(at: [indexPath])
        self.collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView?.register(ProductViewCell.self, forCellWithReuseIdentifier: "collectionCell")
        collectionView?.delegate = self
        collectionView?.allowsSelection = true
        collectionView?.allowsMultipleSelection = true
        collectionView?.dataSource = self
        collectionView?.backgroundColor = UIColor.white
        view.addSubview(collectionView!)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as! ProductViewCell
        if cell.isSelected {
            cell.updateBorder(selected: true)
        } else {
            cell.updateBorder(selected: false)
        }
    }

    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! ProductViewCell
        cell.isSelected = true
        cell.updateBorder(selected: true)
        add(amount: cell.price)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! ProductViewCell
        cell.isSelected = false
        cell.updateBorder(selected: false)
        remove(amount: cell.price)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath as IndexPath) as! ProductViewCell
        
        cell.productLabel.text = pets[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenRect = UIScreen.main.bounds
        let screenWidth = screenRect.size.width
        let length = (screenWidth / 2) - 20
        return CGSize(width: length, height: length)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
    }
}
