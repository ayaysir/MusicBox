//
//  PostPageViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/07.
//

import UIKit

class PostPageViewController: UIPageViewController {
    
    var currentIndex: Int!
    var posts: [Post]!
    
    private func vcInstance(name: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: name)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 딜리게이트, 데이터소스 연결
        self.dataSource = self
        self.delegate = self
        
        // 첫 번째 페이지를 기본 페이지로 설정
        guard let postViewVC = vcInstance(name: "PostView") as? PostViewController else {
            return
        }
        let currentPost = posts[currentIndex]
        postViewVC.post = currentPost
        setViewControllers([postViewVC], direction: .forward, animated: true, completion: nil)
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension PostPageViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {

        guard let prevVC = vcInstance(name: "PostView") as? PostViewController else {
            return nil
        }
        // 이전 페이지 인덱스
        currentIndex -= 1
        
        // 인덱스가 0 이상이라면 그냥 놔둠
        guard currentIndex! >= 0 else {
            currentIndex = 0
            
            // currentIndex = posts.count - 1
            // 무한반복 시 - 1페이지에서 마지막 페이지로 가야함
            // prevVC.post = posts[currentIndex]
            return nil
        }
        
        prevVC.post = posts[currentIndex]
        return prevVC
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let nextVC = vcInstance(name: "PostView") as? PostViewController else {
            return nil
        }
        // 다음 페이지 인덱스
        currentIndex += 1
        
        // 인덱스가 0 이상이라면 그냥 놔둠
        guard currentIndex! < posts.count else {
            currentIndex = posts.count - 1
            
            // currentIndex = 0
            // 무한반복 시 - 1페이지에서 마지막 페이지로 가야함
            // nextVC.post = posts[currentIndex]
            return nil
        }
        
        nextVC.post = posts[currentIndex]
        return nextVC
    }
    
    
}
