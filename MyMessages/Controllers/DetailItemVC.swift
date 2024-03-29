//
//  DetailItemVC.swift
//  iBuy
//
//  Created by Camilo Jimenez on 10/08/21.
//

import UIKit
import NotificationBannerSwift

protocol DetailItemVCProtocol: AnyObject {
    func reload()
}

class DetailItemVC: UIViewController {
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var websiteLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    private var viewModel = DetailItemVM()
    private var isFavorite: Bool = false {
        didSet {
            if isFavorite {
                self.navigationItem.rightBarButtonItem = makeFav()
            } else {
                self.navigationItem.rightBarButtonItem = deleteFav()
            }
        }
    }
    weak var delegate: DetailItemVCProtocol?
    var selectedPost: PostModel?
    var commentsOfPost: [CommentModel]?
    var userInfo: UserInformationModel? {
        didSet {
            updateUserInfoInUI()
        }
    }
    
    fileprivate func updateUserInfoInUI() {
        DispatchQueue.main.async {
            self.nameLabel.text = self.userInfo?.name
            self.emailLabel.text = self.userInfo?.email
            self.phoneLabel.text = self.userInfo?.phone
            self.websiteLabel.text = self.userInfo?.website
        }
    }
    
    fileprivate func setupTableView() {
        let nib = UINib(nibName: CellIdentifiers.commentatyCell.resource, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: CellIdentifiers.commentatyCell.resource)
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    fileprivate func loadUserInformation() {
        if let userId = self.selectedPost?.userId {
            viewModel.getUserInformation(userId: userId) { userData, error in
                if let error = error {
                    DispatchQueue.main.async {
                        let banner = NotificationBanner(title: "Error", subtitle: error.localizedDescription, style: .danger)
                        //self.loading(show: false)
                        banner.show()
                    }

                } else if let userData = userData {
                    self.userInfo = userData
                }
            }
        }
    }
    
    fileprivate func loadUserComments() {
        if let postId = self.selectedPost?.id {
            viewModel.getCommentsOfPost(postId: postId) { commentsRes, error in
                if let error = error {
                    DispatchQueue.main.async {
                        let banner = NotificationBanner(title: "Error", subtitle: error.localizedDescription, style: .danger)
                        //self.loading(show: false)
                        banner.show()
                    }

                } else if let comments = commentsRes {
                    self.commentsOfPost = comments
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    fileprivate func makeFav() -> UIBarButtonItem {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "starFill")
        button.setImage(image, for: .normal)
        button.addTarget(self, action:#selector(favoriteAction), for: .touchUpInside)
        return UIBarButtonItem(customView: button)
    }
    
    fileprivate func deleteFav() -> UIBarButtonItem {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "starNoFill")
        button.setImage(image, for: .normal)
        button.addTarget(self, action:#selector(favoriteAction), for: .touchUpInside)
        return UIBarButtonItem(customView: button)
    }
    
    @objc func favoriteAction(_ sender: Any) {
        isFavorite = !isFavorite
        if let post = self.selectedPost {
            do {
                try self.viewModel.storePost(state: isFavorite, post: post)
            } catch {
                print(error)
            }
        }
    }
    
    fileprivate func setupStarButton() {
        do {
            if let post = selectedPost {
                self.isFavorite = try viewModel.checkIsFavorite(post: post)
            }
        } catch {
            print(error)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let remoteConnection = RemoteConnection(networkManager: NativeNetworkManager())
        viewModel.remoteUserInfoData = remoteConnection
        viewModel.remoteCommentsData = remoteConnection
        viewModel.storage = SQLiteLocalStorage()
        setupTableView()
        setupStarButton()
        loadUserInformation()
        loadUserComments()
        self.descriptionLabel.text = selectedPost?.body
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.reload()
    }
}

extension DetailItemVC: UITableViewDelegate {

}

extension DetailItemVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commentsOfPost?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.commentatyCell.resource, for: indexPath) as! CommentaryCell
        cell.descriptionLabel.text = commentsOfPost?[indexPath.row].body
        cell.selectionStyle = .none
        return cell
    }
}
