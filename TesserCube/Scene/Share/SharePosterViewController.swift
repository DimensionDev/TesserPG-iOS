//
//  SharePosterViewController.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/24.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit

class SharePosterViewController: TCBaseViewController {
    
    private lazy var bottomActionsView: UIStackView = {
        let stackView = UIStackView(frame: .zero)
        stackView.spacing = 12
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .fill
        return stackView
    }()
    
    private lazy var posterView: UIView = {
        let view = UIView(frame: .zero)
        
        return view
    }()
    
    private lazy var posterImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        return imageView
    }()
    
    private lazy var saveImageButton: TCActionButton = {
        let button = TCActionButton(frame: .zero)
        button.color = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.setTitle(L10n.SharePosterController.Action.Button.saveImage, for: .normal)
        return button
    }()
    
    var activity: UIActivity
    
    init(activity: UIActivity) {
        self.activity = activity
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.SharePosterController.title
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonDidClicked(_:)))
        
        addBottomActionsView()
        addPosterImageView()
    }
    
    private func addBottomActionsView() {
        view.addSubview(bottomActionsView)
        
        bottomActionsView.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(view.layoutMarginsGuide)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).offset(-15)
        }
        
        saveImageButton.addTarget(self, action: #selector(saveImageButtonClicked(_:)), for: .touchUpInside)
        
        let shareImageButton = TCActionButton(frame: .zero)
        shareImageButton.color = .systemBlue
        shareImageButton.setTitleColor(.white, for: .normal)
        shareImageButton.setTitle(L10n.SharePosterController.Action.Button.shareImage, for: .normal)
        shareImageButton.addTarget(self, action: #selector(shareImageButtonClicked(_:)), for: .touchUpInside)
        
        let bottomStackView = UIStackView(arrangedSubviews: [saveImageButton, shareImageButton], axis: .horizontal, spacing: 15, alignment: .fill, distribution: .fillEqually)
        
        bottomActionsView.addArrangedSubview(bottomStackView)
    }
    
    private func addPosterImageView() {
        posterImageView.image = Asset.mockPoster.image
        posterView.addSubview(posterImageView)
        view.addSubview(posterView)
        
        posterImageView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        
        posterView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(view.layoutMarginsGuide).offset(16)
            maker.bottom.equalTo(bottomActionsView.snp.top).offset(-20)
            maker.width.equalTo(posterView.snp.height).multipliedBy(275.0 / 490.0)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        posterView.layer.addSketchShadow(color: .black, alpha: 0.22, x: 0, y: 5, blur: 17, spread: 0, roundedRect: posterView.bounds, byRoundingCorners: .allCorners, cornerRadii: .zero)
    }
    
    @objc
    private func doneButtonDidClicked(_ sender: UIBarButtonItem) {
        activity.activityDidFinish(true)
    }
    
    @objc
    private func saveImageButtonClicked(_ sender: UIButton) {
        guard let toSaveImage = posterImageView.image else {
            return
        }
        saveImageButton.isEnabled = false
        DispatchQueue.global().async {
            UIImageWriteToSavedPhotosAlbum(toSaveImage, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        DispatchQueue.main.async {
            if let error = error {
                // we got back an error!
                self.showSimpleAlert(title: "Save Image Error", message: error.localizedDescription)
                self.saveImageButton.isEnabled = true
            } else {
                self.saveImageButton.isEnabled = false
            }
        }
    }
    
    @objc
    private func shareImageButtonClicked(_ sender: UIButton) {
        let vc = UIActivityViewController(activityItems: [posterImageView.image!], applicationActivities: nil)
        vc.completionWithItemsHandler = { type, result, items, error in
            
        }
        present(vc, animated: true)
    }
}

extension SharePosterViewController {
    static func createWithNavigation(activity: UIActivity) -> UINavigationController {
        let vc = SharePosterViewController(activity: activity)
        let naviVC = UINavigationController(rootViewController: vc)
        return naviVC
    }
}
