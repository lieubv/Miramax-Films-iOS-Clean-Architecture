//
//  MovieViewController.swift
//  Miramax Fillms
//
//  Created by Thanh Quang on 12/09/2022.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import SwifterSwift
import Domain

class MovieViewController: BaseViewController<MovieViewModel>, Searchable {
    
    // MARK: - Outlets + Views
    
    @IBOutlet weak var appToolbar: AppToolbar!
    @IBOutlet weak var scrollView: UIScrollView!
    
    /// Section genres
    @IBOutlet weak var genresCollectionView: UICollectionView!
    @IBOutlet weak var genresLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var genresRetryButton: PrimaryButton!
    
    /// Section upcoming
    @IBOutlet weak var sectionUpcomingView: UIView!
    @IBOutlet weak var upcomingSectionHeaderView: SectionHeaderView!
    @IBOutlet weak var upcomingCollectionView: UICollectionView!
    @IBOutlet weak var upcomingLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var upcomingRetryButton: PrimaryButton!
    
    /// Section selfie
    @IBOutlet weak var sectionSelfieView: UIView!
    @IBOutlet weak var selfieSectionHeaderView: SectionHeaderView!
    @IBOutlet weak var selfieView: SelfieWithMovieView!
    
    /// Section tab layout
    @IBOutlet weak var sectionTabLayoutView: UIView!
    @IBOutlet weak var tabLayout: TabLayout!
    
    /// Section preview
    @IBOutlet weak var sectionPreviewView: UIView!
    @IBOutlet weak var previewCollectionView: SelfSizingCollectionView!
    @IBOutlet weak var previewCollectionViewHc: NSLayoutConstraint!
    @IBOutlet weak var previewLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var previewRetryButton: PrimaryButton!
    
    var btnSearch: SearchButton = SearchButton()

    // MARK: - Properties
    
    private let genresDataS = BehaviorRelay<[Genre]>(value: [])
    private let upcomingDataS = BehaviorRelay<[EntertainmentModelType]>(value: [])
    private let previewDataS = BehaviorRelay<[EntertainmentModelType]>(value: [])

    private let previewTabTriggerS = PublishRelay<MoviePreviewTab>()
    private let entertainmentSelectTriggerS = PublishRelay<EntertainmentModelType>()
    private let genreSelectTriggerS = PublishRelay<Genre>()

    // MARK: - Lifecycle
    
    override func configView() {
        super.configView()
        
        configureAppToolbar()
        configureSectionGenres()
        configureSectionUpcoming()
        configureSelfieView()
        configureSectionTabLayout()
        configureSectionPreview()
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        
        let input = MovieViewModel.Input(
            toSearchTrigger: btnSearch.rx.tap.asDriver(),
            retryGenreTrigger: Driver.empty(),
            retryUpcomingTrigger: Driver.empty(),
            retryPreviewTrigger: Driver.empty(),
            selectionEntertainmentTrigger: entertainmentSelectTriggerS.asDriverOnErrorJustComplete(),
            selectionGenreTrigger: genreSelectTriggerS.asDriverOnErrorJustComplete(),
            previewTabTrigger: previewTabTriggerS.asDriverOnErrorJustComplete()
        )
        let output = viewModel.transform(input: input)
        
        output.genresViewState
            .drive(onNext: { [weak self] viewState in
                guard let self = self else { return }
                switch viewState {
                case .initial, .paging:
                    break
                case .populated(let items):
                    self.genresLoadingIndicator.stopAnimating()
                    self.genresDataS.accept(items)
                case .error:
                    self.genresLoadingIndicator.stopAnimating()
                    self.genresRetryButton.isHidden = false
                }
            })
            .disposed(by: rx.disposeBag)
        
        output.upcomingViewState
            .drive(onNext: { [weak self] viewState in
                guard let self = self else { return }
                switch viewState {
                case .initial, .paging:
                    break
                case .populated(let items):
                    self.upcomingLoadingIndicator.stopAnimating()
                    self.upcomingDataS.accept(items)
                case .error:
                    self.upcomingLoadingIndicator.stopAnimating()
                    self.upcomingRetryButton.isHidden = false
                }
            })
            .disposed(by: rx.disposeBag)
        
        output.previewViewState
            .drive(onNext: { [weak self] viewState in
                guard let self = self else { return }
                switch viewState {
                case .initial, .paging:
                    break
                case .populated(let items):
                    self.previewLoadingIndicator.stopAnimating()
                    self.previewCollectionView.isHidden = false
                    self.previewRetryButton.isHidden = true
                    self.previewDataS.accept(items)
                case .error:
                    self.previewLoadingIndicator.stopAnimating()
                    self.previewCollectionView.isHidden = true
                    self.previewRetryButton.isHidden = false
                }
            })
            .disposed(by: rx.disposeBag)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let previewContentHeight = previewCollectionView.intrinsicContentSize.height
        previewCollectionViewHc.constant = previewContentHeight < DimensionConstants.moviePreviewCollectionViewMinHeight ? DimensionConstants.moviePreviewCollectionViewMinHeight : previewContentHeight
    }
}

// MARK: - Private functions

extension MovieViewController {
    private func configureAppToolbar() {
        appToolbar.title = "movie".localized
        appToolbar.showBackButton = false
        appToolbar.rightButtons = [btnSearch]
    }
    
    private func configureSectionGenres() {
        genresLoadingIndicator.startAnimating()
        
        genresRetryButton.titleText = "retry".localized
        genresRetryButton.isHidden = true
        
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.itemSize = .init(width: 96.0, height: DimensionConstants.genreCellHeight)
        collectionViewLayout.sectionInset = .init(top: 0.0, left: 16.0, bottom: 0.0, right: 16.0)
        collectionViewLayout.minimumLineSpacing = 12.0
        genresCollectionView.collectionViewLayout = collectionViewLayout
        genresCollectionView.showsHorizontalScrollIndicator = false
        genresCollectionView.register(cellWithClass: GenreCell.self)
        genresCollectionView.rx.modelSelected(Genre.self)
            .bind(to: genreSelectTriggerS)
            .disposed(by: rx.disposeBag)

        let dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<String, Genre>> { dataSource, collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(withClass: GenreCell.self, for: indexPath)
            cell.bind(item)
            return cell
        }
        
        genresDataS
            .map { [SectionModel(model: "", items: $0)] }
            .bind(to: genresCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
    }
    
    private func configureSectionUpcoming() {
        upcomingSectionHeaderView.title = "upcoming".localized

        upcomingLoadingIndicator.startAnimating()
        
        upcomingRetryButton.titleText = "retry".localized
        upcomingRetryButton.isHidden = true
        
        let collectionViewLayout = ColumnFlowLayout(
            cellsPerRow: 1,
            ratio: DimensionConstants.entertainmentHorizontalCellRatio,
            minimumInteritemSpacing: 0.0,
            minimumLineSpacing: DimensionConstants.entertainmentHorizontalCellSpacing,
            sectionInset: .init(top: 0, left: 16.0, bottom: 0.0, right: 16.0),
            scrollDirection: .horizontal
        )
        upcomingCollectionView.collectionViewLayout = collectionViewLayout
        upcomingCollectionView.showsHorizontalScrollIndicator = false
        upcomingCollectionView.register(cellWithClass: EntertainmentHorizontalCell.self)
        upcomingCollectionView.rx.modelSelected(EntertainmentModelType.self)
            .bind(to: entertainmentSelectTriggerS)
            .disposed(by: rx.disposeBag)
        
        let dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<String, EntertainmentModelType>> { dataSource, collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(withClass: EntertainmentHorizontalCell.self, for: indexPath)
            cell.bind(item)
            return cell
        }
        
        upcomingDataS
            .map { [SectionModel(model: "", items: $0)] }
            .bind(to: upcomingCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
    }
    
    private func configureSelfieView() {
        selfieSectionHeaderView.title = "selfie_with_movie".localized
        selfieSectionHeaderView.showSeeMoreButton = false
    }
    
    private func configureSectionTabLayout() {
        tabLayout.titles = ["top_rating".localized, "news".localized, "trending".localized]
        tabLayout.delegate = self
        tabLayout.selectionTitle(index: 1, animated: false)
    }
    
    private func configureSectionPreview() {
        previewLoadingIndicator.startAnimating()
        
        previewRetryButton.titleText = "retry".localized
        previewRetryButton.isHidden = true
        
        let collectionViewLayout = ColumnFlowLayout(
            cellsPerRow: 2,
            ratio: DimensionConstants.entertainmentPreviewCellRatio,
            minimumInteritemSpacing: DimensionConstants.entertainmentPreviewCellSpacing,
            minimumLineSpacing: DimensionConstants.entertainmentPreviewCellSpacing,
            sectionInset: .init(top: 0.0, left: 16.0, bottom: 0.0, right: 16.0),
            scrollDirection: .vertical
        )
        
        previewCollectionView.collectionViewLayout = collectionViewLayout
        previewCollectionView.isScrollEnabled = false
        previewCollectionView.showsVerticalScrollIndicator = false
        previewCollectionView.register(cellWithClass: EntertainmentPreviewCollectionViewCell.self)
        previewCollectionView.rx.modelSelected(EntertainmentModelType.self)
            .bind(to: entertainmentSelectTriggerS)
            .disposed(by: rx.disposeBag)
        
        let dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<String, EntertainmentModelType>> { dataSource, collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(withClass: EntertainmentPreviewCollectionViewCell.self, for: indexPath)
            cell.bind(item)
            return cell
        }
        
        previewDataS
            .map { [SectionModel(model: "", items: $0)] }
            .bind(to: previewCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
    }
}

// MARK: - TabLayoutDelegate

extension MovieViewController: TabLayoutDelegate {
    func didSelectAtIndex(_ index: Int) {
        previewLoadingIndicator.startAnimating()
        previewRetryButton.isHidden = true
        previewCollectionView.isHidden = true
        switch index {
        case 0:
            previewTabTriggerS.accept(.topRating)
        case 1:
            previewTabTriggerS.accept(.news)
        case 2:
            previewTabTriggerS.accept(.trending)
        default:
            break
        }
    }
}
