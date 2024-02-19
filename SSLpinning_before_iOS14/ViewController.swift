import UIKit

class ViewController: UIViewController {

    
    private var resultLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textColor = .black
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    private func setupViews() {
        view.backgroundColor = .white

        let button = UIButton(type: .system)
        button.setTitle("Perform POST Request", for: .normal)
        button.addTarget(self, action: #selector(postData), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        view.addSubview(resultLabel)
        NSLayoutConstraint.activate([
            resultLabel.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 20),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    @objc private func postData() {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else {
            print("Invalid URL")
            return
        }

        let parameters = ["title": "foo", "body": "bar", "userId": "1"]
        guard let postData = try? JSONSerialization.data(withJSONObject: parameters) else {
            print("Failed to serialize JSON")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = postData
        
        NetworkManager.shared.request(url: request, expecting: PostResponse.self) { data, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

                DispatchQueue.main.async {
                    self.resultLabel.text = "Post ID: \(data.id)"
                }
        }
        
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, error == nil else {
//                print("Error: \(error?.localizedDescription ?? "Unknown error")")
//                return
//            }
//
//            if let httpResponse = response as? HTTPURLResponse {
//                print("Status Code: \(httpResponse.statusCode)")
//            }
//
//            if let decodedData = try? JSONDecoder().decode(PostResponse.self, from: data) {
//                DispatchQueue.main.async {
//                    self.resultLabel.text = "Post ID: \(decodedData.id)"
//                }
//            } else {
//                print("Failed to decode response")
//            }
//        }.resume()
    }
}

struct PostResponse: Decodable {
    let id: Int
}
