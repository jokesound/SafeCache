#import "MainViewController.h"
#import "AppRecord.h"
#import "AppScanner.h"
#import "CacheCleaner.h"
#import "SettingsStore.h"

#pragma mark - App cell

@interface SafeCacheAppCell : UITableViewCell
@property (nonatomic, strong) UIView *avatarView;
@property (nonatomic, strong) UILabel *avatarLabel;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UILabel *badgeLabel;
@property (nonatomic, strong) UIImageView *stateImageView;
- (void)configureWithRecord:(AppRecord *)record detail:(NSString *)detail;
@end

@implementation SafeCacheAppCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        self.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _avatarView = [UIView new];
        _avatarView.translatesAutoresizingMaskIntoConstraints = NO;
        _avatarView.backgroundColor = UIColor.tertiarySystemFillColor;
        _avatarView.layer.cornerRadius = 12;

        _avatarLabel = [UILabel new];
        _avatarLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _avatarLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
        _avatarLabel.textColor = UIColor.systemBlueColor;
        _avatarLabel.textAlignment = NSTextAlignmentCenter;

        _nameLabel = [UILabel new];
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _nameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        _nameLabel.adjustsFontForContentSizeCategory = YES;
        _nameLabel.numberOfLines = 1;

        _detailLabel = [UILabel new];
        _detailLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _detailLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        _detailLabel.adjustsFontForContentSizeCategory = YES;
        _detailLabel.textColor = UIColor.secondaryLabelColor;
        _detailLabel.numberOfLines = 1;

        _badgeLabel = [UILabel new];
        _badgeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _badgeLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
        _badgeLabel.textAlignment = NSTextAlignmentCenter;
        _badgeLabel.layer.cornerRadius = 9;
        _badgeLabel.layer.masksToBounds = YES;
        _badgeLabel.hidden = YES;

        _stateImageView = [UIImageView new];
        _stateImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _stateImageView.contentMode = UIViewContentModeScaleAspectFit;
        _stateImageView.preferredSymbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:23 weight:UIImageSymbolWeightRegular];

        [self.contentView addSubview:_avatarView];
        [_avatarView addSubview:_avatarLabel];
        [self.contentView addSubview:_nameLabel];
        [self.contentView addSubview:_detailLabel];
        [self.contentView addSubview:_badgeLabel];
        [self.contentView addSubview:_stateImageView];

        [NSLayoutConstraint activateConstraints:@[
            [_avatarView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
            [_avatarView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_avatarView.widthAnchor constraintEqualToConstant:44],
            [_avatarView.heightAnchor constraintEqualToConstant:44],
            [_avatarLabel.centerXAnchor constraintEqualToAnchor:_avatarView.centerXAnchor],
            [_avatarLabel.centerYAnchor constraintEqualToAnchor:_avatarView.centerYAnchor],

            [_stateImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
            [_stateImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_stateImageView.widthAnchor constraintEqualToConstant:26],
            [_stateImageView.heightAnchor constraintEqualToConstant:26],

            [_badgeLabel.trailingAnchor constraintEqualToAnchor:_stateImageView.leadingAnchor constant:-10],
            [_badgeLabel.centerYAnchor constraintEqualToAnchor:_nameLabel.centerYAnchor],
            [_badgeLabel.widthAnchor constraintGreaterThanOrEqualToConstant:48],
            [_badgeLabel.heightAnchor constraintEqualToConstant:18],

            [_nameLabel.leadingAnchor constraintEqualToAnchor:_avatarView.trailingAnchor constant:12],
            [_nameLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:13],
            [_nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_badgeLabel.leadingAnchor constant:-8],

            [_detailLabel.leadingAnchor constraintEqualToAnchor:_nameLabel.leadingAnchor],
            [_detailLabel.topAnchor constraintEqualToAnchor:_nameLabel.bottomAnchor constant:4],
            [_detailLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_stateImageView.leadingAnchor constant:-10],
            [_detailLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor constant:-12],
        ]];
    }
    return self;
}

- (NSString *)initialForName:(NSString *)name {
    if (name.length == 0) return @"?";
    NSRange range = [name rangeOfComposedCharacterSequenceAtIndex:0];
    return [[name substringWithRange:range] uppercaseString];
}

- (void)configureWithRecord:(AppRecord *)record detail:(NSString *)detail {
    self.nameLabel.text = record.name;
    self.detailLabel.text = detail;
    self.avatarLabel.text = [self initialForName:record.name];

    if (record.whitelisted) {
        self.nameLabel.textColor = UIColor.labelColor;
        self.avatarView.backgroundColor = UIColor.systemGreenColor;
        self.avatarLabel.textColor = UIColor.whiteColor;
        self.badgeLabel.hidden = NO;
        self.badgeLabel.text = @"白名单";
        self.badgeLabel.textColor = UIColor.systemGreenColor;
        self.badgeLabel.backgroundColor = [UIColor.systemGreenColor colorWithAlphaComponent:0.12];
        self.stateImageView.image = [UIImage systemImageNamed:@"shield.fill"];
        self.stateImageView.tintColor = UIColor.systemGreenColor;
    } else {
        self.nameLabel.textColor = UIColor.labelColor;
        self.avatarView.backgroundColor = UIColor.tertiarySystemFillColor;
        self.avatarLabel.textColor = UIColor.systemBlueColor;
        self.badgeLabel.hidden = YES;
        self.stateImageView.image = [UIImage systemImageNamed:(record.selected ? @"checkmark.circle.fill" : @"circle")];
        self.stateImageView.tintColor = record.selected ? UIColor.systemBlueColor : UIColor.tertiaryLabelColor;
    }
}

@end

#pragma mark - Main view controller

@interface MainViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *amountLabel;
@property (nonatomic, strong) UILabel *summaryLabel;
@property (nonatomic, strong) UILabel *selectedLabel;
@property (nonatomic, strong) UISwitch *tmpSwitch;
@property (nonatomic, strong) UIButton *cleanButton;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, copy) NSArray<AppRecord *> *apps;
@property (nonatomic, strong) AppScanner *scanner;
@property (nonatomic, strong) CacheCleaner *cleaner;
@property (nonatomic, strong) SettingsStore *settings;
@property (nonatomic) BOOL scanning;
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"SafeCache";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;

    self.scanner = [AppScanner new];
    self.cleaner = [CacheCleaner new];
    self.settings = [SettingsStore new];
    self.apps = @[];

    UIBarButtonItem *scan = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrow.clockwise"] style:UIBarButtonItemStylePlain target:self action:@selector(scanTapped)];
    scan.accessibilityLabel = @"扫描";
    UIBarButtonItem *menu = [[UIBarButtonItem alloc] initWithTitle:@"批量" style:UIBarButtonItemStylePlain target:self action:@selector(batchTapped)];
    self.navigationItem.leftBarButtonItem = scan;
    self.navigationItem.rightBarButtonItem = menu;

    UIView *summaryCard = [UIView new];
    summaryCard.translatesAutoresizingMaskIntoConstraints = NO;
    summaryCard.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    summaryCard.layer.cornerRadius = 18;
    summaryCard.layer.cornerCurve = kCACornerCurveContinuous;

    UILabel *eyebrow = [UILabel new];
    eyebrow.translatesAutoresizingMaskIntoConstraints = NO;
    eyebrow.text = @"可清理标准缓存";
    eyebrow.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    eyebrow.textColor = UIColor.secondaryLabelColor;

    self.amountLabel = [UILabel new];
    self.amountLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.amountLabel.text = @"—";
    self.amountLabel.font = [UIFont monospacedDigitSystemFontOfSize:34 weight:UIFontWeightBold];
    self.amountLabel.adjustsFontSizeToFitWidth = YES;
    self.amountLabel.minimumScaleFactor = 0.75;

    self.summaryLabel = [UILabel new];
    self.summaryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.summaryLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.summaryLabel.textColor = UIColor.secondaryLabelColor;
    self.summaryLabel.numberOfLines = 0;
    self.summaryLabel.text = @"只读取缓存大小。未选择任何 App 时不会删除任何内容。";

    UIImageView *shield = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"checkmark.shield.fill"]];
    shield.translatesAutoresizingMaskIntoConstraints = NO;
    shield.tintColor = UIColor.systemGreenColor;
    shield.preferredSymbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:23 weight:UIImageSymbolWeightSemibold];

    [summaryCard addSubview:eyebrow];
    [summaryCard addSubview:self.amountLabel];
    [summaryCard addSubview:self.summaryLabel];
    [summaryCard addSubview:shield];
    [self.view addSubview:summaryCard];

    UIView *scopeCard = [UIView new];
    scopeCard.translatesAutoresizingMaskIntoConstraints = NO;
    scopeCard.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    scopeCard.layer.cornerRadius = 14;
    scopeCard.layer.cornerCurve = kCACornerCurveContinuous;

    UIImageView *folderIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"folder.badge.gearshape"]];
    folderIcon.translatesAutoresizingMaskIntoConstraints = NO;
    folderIcon.tintColor = UIColor.systemBlueColor;

    UILabel *scopeTitle = [UILabel new];
    scopeTitle.translatesAutoresizingMaskIntoConstraints = NO;
    scopeTitle.text = @"同时清理临时目录 tmp";
    scopeTitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];

    UILabel *scopeDetail = [UILabel new];
    scopeDetail.translatesAutoresizingMaskIntoConstraints = NO;
    scopeDetail.text = @"默认关闭；建议日常只清 Library/Caches";
    scopeDetail.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    scopeDetail.textColor = UIColor.secondaryLabelColor;

    self.tmpSwitch = [UISwitch new];
    self.tmpSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    self.tmpSwitch.on = self.settings.includeTmp;
    [self.tmpSwitch addTarget:self action:@selector(tmpChanged:) forControlEvents:UIControlEventValueChanged];

    [scopeCard addSubview:folderIcon];
    [scopeCard addSubview:scopeTitle];
    [scopeCard addSubview:scopeDetail];
    [scopeCard addSubview:self.tmpSwitch];
    [self.view addSubview:scopeCard];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 70;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 72, 0, 16);
    [self.tableView registerClass:SafeCacheAppCell.class forCellReuseIdentifier:@"app"];
    [self.view addSubview:self.tableView];

    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(scanTapped) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = self.refreshControl;

    UIView *bottomBar = [UIView new];
    bottomBar.translatesAutoresizingMaskIntoConstraints = NO;
    bottomBar.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    bottomBar.layer.cornerRadius = 18;
    bottomBar.layer.cornerCurve = kCACornerCurveContinuous;

    self.selectedLabel = [UILabel new];
    self.selectedLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.selectedLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.selectedLabel.textColor = UIColor.secondaryLabelColor;
    self.selectedLabel.text = @"未选择 App";

    self.cleanButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.cleanButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.cleanButton.backgroundColor = UIColor.systemBlueColor;
    [self.cleanButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.cleanButton setTitleColor:[UIColor.whiteColor colorWithAlphaComponent:0.65] forState:UIControlStateDisabled];
    self.cleanButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.cleanButton setTitle:@"清理已选" forState:UIControlStateNormal];
    self.cleanButton.layer.cornerRadius = 12;
    self.cleanButton.layer.cornerCurve = kCACornerCurveContinuous;
    self.cleanButton.contentEdgeInsets = UIEdgeInsetsMake(0, 18, 0, 18);
    self.cleanButton.enabled = NO;
    [self.cleanButton addTarget:self action:@selector(cleanTapped) forControlEvents:UIControlEventTouchUpInside];

    [bottomBar addSubview:self.selectedLabel];
    [bottomBar addSubview:self.cleanButton];
    [self.view addSubview:bottomBar];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [summaryCard.topAnchor constraintEqualToAnchor:safe.topAnchor constant:8],
        [summaryCard.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [summaryCard.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],

        [eyebrow.leadingAnchor constraintEqualToAnchor:summaryCard.leadingAnchor constant:18],
        [eyebrow.topAnchor constraintEqualToAnchor:summaryCard.topAnchor constant:16],
        [eyebrow.trailingAnchor constraintLessThanOrEqualToAnchor:shield.leadingAnchor constant:-10],
        [shield.trailingAnchor constraintEqualToAnchor:summaryCard.trailingAnchor constant:-18],
        [shield.centerYAnchor constraintEqualToAnchor:eyebrow.centerYAnchor],
        [shield.widthAnchor constraintEqualToConstant:28],
        [shield.heightAnchor constraintEqualToConstant:28],
        [self.amountLabel.leadingAnchor constraintEqualToAnchor:summaryCard.leadingAnchor constant:18],
        [self.amountLabel.topAnchor constraintEqualToAnchor:eyebrow.bottomAnchor constant:4],
        [self.amountLabel.trailingAnchor constraintEqualToAnchor:summaryCard.trailingAnchor constant:-18],
        [self.summaryLabel.leadingAnchor constraintEqualToAnchor:summaryCard.leadingAnchor constant:18],
        [self.summaryLabel.topAnchor constraintEqualToAnchor:self.amountLabel.bottomAnchor constant:6],
        [self.summaryLabel.trailingAnchor constraintEqualToAnchor:summaryCard.trailingAnchor constant:-18],
        [self.summaryLabel.bottomAnchor constraintEqualToAnchor:summaryCard.bottomAnchor constant:-16],

        [scopeCard.topAnchor constraintEqualToAnchor:summaryCard.bottomAnchor constant:10],
        [scopeCard.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [scopeCard.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [scopeCard.heightAnchor constraintEqualToConstant:68],
        [folderIcon.leadingAnchor constraintEqualToAnchor:scopeCard.leadingAnchor constant:16],
        [folderIcon.centerYAnchor constraintEqualToAnchor:scopeCard.centerYAnchor],
        [folderIcon.widthAnchor constraintEqualToConstant:24],
        [folderIcon.heightAnchor constraintEqualToConstant:24],
        [scopeTitle.leadingAnchor constraintEqualToAnchor:folderIcon.trailingAnchor constant:12],
        [scopeTitle.topAnchor constraintEqualToAnchor:scopeCard.topAnchor constant:12],
        [scopeTitle.trailingAnchor constraintLessThanOrEqualToAnchor:self.tmpSwitch.leadingAnchor constant:-12],
        [scopeDetail.leadingAnchor constraintEqualToAnchor:scopeTitle.leadingAnchor],
        [scopeDetail.topAnchor constraintEqualToAnchor:scopeTitle.bottomAnchor constant:3],
        [scopeDetail.trailingAnchor constraintLessThanOrEqualToAnchor:self.tmpSwitch.leadingAnchor constant:-12],
        [self.tmpSwitch.trailingAnchor constraintEqualToAnchor:scopeCard.trailingAnchor constant:-16],
        [self.tmpSwitch.centerYAnchor constraintEqualToAnchor:scopeCard.centerYAnchor],

        [self.tableView.topAnchor constraintEqualToAnchor:scopeCard.bottomAnchor constant:2],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:bottomBar.topAnchor constant:-8],

        [bottomBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [bottomBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [bottomBar.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-8],
        [bottomBar.heightAnchor constraintEqualToConstant:64],
        [self.selectedLabel.leadingAnchor constraintEqualToAnchor:bottomBar.leadingAnchor constant:16],
        [self.selectedLabel.centerYAnchor constraintEqualToAnchor:bottomBar.centerYAnchor],
        [self.selectedLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.cleanButton.leadingAnchor constant:-10],
        [self.cleanButton.trailingAnchor constraintEqualToAnchor:bottomBar.trailingAnchor constant:-10],
        [self.cleanButton.topAnchor constraintEqualToAnchor:bottomBar.topAnchor constant:10],
        [self.cleanButton.bottomAnchor constraintEqualToAnchor:bottomBar.bottomAnchor constant:-10],
        [self.cleanButton.widthAnchor constraintGreaterThanOrEqualToConstant:112],
    ]];

    [self scanTapped];
}

- (NSString *)sizeText:(unsigned long long)bytes {
    NSByteCountFormatter *f = [NSByteCountFormatter new];
    f.countStyle = NSByteCountFormatterCountStyleFile;
    return [f stringFromByteCount:(long long)bytes];
}

- (unsigned long long)selectedBytes {
    unsigned long long total = 0;
    for (AppRecord *r in self.apps) {
        if (r.selected && !r.whitelisted) total += r.cacheBytes + r.tmpBytes;
    }
    return total;
}

- (NSUInteger)selectedCount {
    NSUInteger count = 0;
    for (AppRecord *r in self.apps) if (r.selected && !r.whitelisted) count++;
    return count;
}

- (void)updateSelectionUI {
    NSUInteger count = [self selectedCount];
    unsigned long long bytes = [self selectedBytes];
    self.cleanButton.enabled = count > 0 && !self.scanning;
    if (count == 0) {
        self.selectedLabel.text = @"未选择 App";
        [self.cleanButton setTitle:@"清理已选" forState:UIControlStateNormal];
    } else {
        self.selectedLabel.text = [NSString stringWithFormat:@"已选 %lu 个 · %@", (unsigned long)count, [self sizeText:bytes]];
        [self.cleanButton setTitle:@"安全清理" forState:UIControlStateNormal];
    }
}

- (void)setScanningState:(BOOL)scanning {
    self.scanning = scanning;
    self.navigationItem.leftBarButtonItem.enabled = !scanning;
    self.navigationItem.rightBarButtonItem.enabled = !scanning;
    self.tmpSwitch.enabled = !scanning;
    if (!scanning && self.refreshControl.isRefreshing) [self.refreshControl endRefreshing];
    [self updateSelectionUI];
}

- (void)tmpChanged:(UISwitch *)sender {
    self.settings.includeTmp = sender.isOn;
    [self scanTapped];
}

- (void)scanTapped {
    if (self.scanning) return;
    [self setScanningState:YES];
    self.amountLabel.text = @"扫描中…";
    self.summaryLabel.text = @"正在读取各 App 的标准缓存目录，不会修改文件。";

    BOOL includeTmp = self.settings.includeTmp;
    NSSet *wl = [self.settings whitelist].copy;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSArray *items = [self.scanner scanAppsIncludeTmp:includeTmp whitelist:wl];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.apps = items;
            unsigned long long total = 0;
            NSUInteger cleanable = 0;
            for (AppRecord *r in items) {
                if (!r.whitelisted) {
                    total += r.cacheBytes + r.tmpBytes;
                    if (r.cacheBytes + r.tmpBytes > 0) cleanable++;
                }
            }
            self.amountLabel.text = [self sizeText:total];
            self.summaryLabel.text = [NSString stringWithFormat:@"%lu 个 App 有可清理内容 · 白名单不会参与批量选择", (unsigned long)cleanable];
            [self.tableView reloadData];
            [self setScanningState:NO];
        });
    });
}

- (void)batchTapped {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"批量操作" message:@"白名单 App 永远不会被批量选中。" preferredStyle:UIAlertControllerStyleActionSheet];
    [a addAction:[UIAlertAction actionWithTitle:@"全选有缓存的 App" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        for (AppRecord *r in self.apps) r.selected = !r.whitelisted && (r.cacheBytes + r.tmpBytes > 0);
        [self.tableView reloadData];
        [self updateSelectionUI];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"取消全部选择" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        for (AppRecord *r in self.apps) r.selected = NO;
        [self.tableView reloadData];
        [self updateSelectionUI];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"把已选加入白名单" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSMutableSet *wl = [self.settings whitelist];
        for (AppRecord *r in self.apps) if (r.selected) [wl addObject:r.bundleID];
        [self.settings saveWhitelist:wl];
        for (AppRecord *r in self.apps) {
            r.whitelisted = [wl containsObject:r.bundleID];
            if (r.whitelisted) r.selected = NO;
        }
        [self.tableView reloadData];
        [self updateSelectionUI];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    if (a.popoverPresentationController) a.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    [self presentViewController:a animated:YES completion:nil];
}

- (void)cleanTapped {
    NSMutableArray<AppRecord *> *selected = [NSMutableArray array];
    for (AppRecord *r in self.apps) if (r.selected && !r.whitelisted) [selected addObject:r];
    if (selected.count == 0) return;

    NSString *scope = self.settings.includeTmp ? @"Library/Caches + tmp" : @"仅 Library/Caches";
    NSString *msg = [NSString stringWithFormat:@"将清理 %lu 个 App，扫描值约 %@。\n\n范围：%@\n\n不会删除 Documents、Application Support、数据库、偏好设置或白名单 App。建议先退出目标 App。", (unsigned long)selected.count, [self sizeText:[self selectedBytes]], scope];
    UIAlertController *confirm = [UIAlertController alertControllerWithTitle:@"确认安全清理" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [confirm addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [confirm addAction:[UIAlertAction actionWithTitle:@"清理" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        [self performClean:selected];
    }]];
    [self presentViewController:confirm animated:YES completion:nil];
}

- (void)performClean:(NSArray<AppRecord *> *)selected {
    [self setScanningState:YES];
    self.summaryLabel.text = @"正在按安全路径规则逐项清理…";
    BOOL includeTmp = self.settings.includeTmp;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        __block unsigned long long freed = 0;
        NSMutableArray<NSString *> *logs = [NSMutableArray array];
        for (AppRecord *r in selected) {
            unsigned long long one = [self.cleaner cleanRecord:r includeTmp:includeTmp log:^(NSString *message) {
                @synchronized (logs) { [logs addObject:message]; }
            }];
            freed += one;
            @synchronized (logs) {
                [logs addObject:[NSString stringWithFormat:@"%@：释放 %@", r.name, [self sizeText:one]]];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setScanningState:NO];
            NSString *detail = logs.count ? [logs componentsJoinedByString:@"\n"] : @"无异常日志。";
            if (detail.length > 1800) detail = [[detail substringToIndex:1800] stringByAppendingString:@"\n…日志已截断"];
            UIAlertController *done = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"已释放 %@", [self sizeText:freed]] message:detail preferredStyle:UIAlertControllerStyleAlert];
            [done addAction:[UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) { [self scanTapped]; }]];
            [self presentViewController:done animated:YES completion:nil];
        });
    });
}

#pragma mark - Table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.apps.count; }

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.apps.count ? @"点按选择 · 左滑可加入/移出白名单" : nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return self.apps.count ? @"白名单会保存在本机。默认白名单包含微信。" : @"下拉或点左上角刷新按钮重新扫描。";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SafeCacheAppCell *cell = [tableView dequeueReusableCellWithIdentifier:@"app" forIndexPath:indexPath];
    AppRecord *r = self.apps[indexPath.row];

    NSString *detail = nil;
    if (self.settings.includeTmp) {
        detail = [NSString stringWithFormat:@"缓存 %@ · tmp %@", [self sizeText:r.cacheBytes], [self sizeText:r.tmpBytes]];
    } else {
        detail = [NSString stringWithFormat:@"缓存 %@", [self sizeText:r.cacheBytes]];
    }
    [cell configureWithRecord:r detail:detail];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AppRecord *r = self.apps[indexPath.row];
    if (r.whitelisted) {
        [self showWhitelistDialog:r];
        return;
    }
    if (r.cacheBytes + r.tmpBytes == 0) return;
    r.selected = !r.selected;
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [self updateSelectionUI];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    AppRecord *r = self.apps[indexPath.row];
    NSString *title = r.whitelisted ? @"移出白名单" : @"加入白名单";
    UIContextualAction *action = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:title handler:^(__unused UIContextualAction *contextualAction, __unused UIView *sourceView, void (^completionHandler)(BOOL)) {
        [self toggleWhitelist:r];
        completionHandler(YES);
    }];
    action.backgroundColor = r.whitelisted ? UIColor.systemOrangeColor : UIColor.systemGreenColor;
    action.image = [UIImage systemImageNamed:(r.whitelisted ? @"shield.slash" : @"shield.fill")];
    UISwipeActionsConfiguration *config = [UISwipeActionsConfiguration configurationWithActions:@[action]];
    config.performsFirstActionWithFullSwipe = NO;
    return config;
}

- (void)showWhitelistDialog:(AppRecord *)r {
    NSString *title = r.whitelisted ? @"白名单保护中" : @"App 信息";
    NSString *msg = [NSString stringWithFormat:@"%@\n%@\n\n白名单 App 不会被全选，也不会执行清理。", r.name, r.bundleID];
    UIAlertController *a = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:(r.whitelisted ? @"移出白名单" : @"加入白名单") style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) { [self toggleWhitelist:r]; }]];
    [a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)toggleWhitelist:(AppRecord *)r {
    NSMutableSet *wl = [self.settings whitelist];
    if ([wl containsObject:r.bundleID]) [wl removeObject:r.bundleID]; else [wl addObject:r.bundleID];
    [self.settings saveWhitelist:wl];
    r.whitelisted = [wl containsObject:r.bundleID];
    if (r.whitelisted) r.selected = NO;
    [self.tableView reloadData];
    [self updateSelectionUI];
}

@end
