//
//  NNListViewController.m
//  NeverNote
//
//  Created by Nathan Fennel on 8/29/14.
//  Copyright (c) 2014 Nathan Fennel. All rights reserved.
//

#import "NNListViewController.h"
#import "UIColor+AppColors.h"

@interface NNListViewController ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *dataArray;

@end

@implementation NNListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.dataArray = [NSMutableArray new];
    [self setUpTableView];

    [self.view addSubview:self.tableView];
    [self.view addSubview:self.scrollView];
}


- (void)setUpTableView {
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:TableCellIdentifier];
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 40.0f, 320.0f, 500.0f)];
        [_scrollView setContentSize:CGSizeMake(320.0f, 20000)];
        [_scrollView setDelegate:self];
        [_scrollView setBackgroundColor:[UIColor lightGrayAppColor]];
        
        for (int i = 0; i < _scrollView.contentSize.height; i++) {
            int x = arc4random()%320;
            int y = arc4random()%50;
            y+=50;
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(x, i, 320 - x, y)];
            i+=y;
            [view setBackgroundColor:[UIColor randomPastelColor]];
            [_scrollView addSubview:view];
        }
    }
    
    return _scrollView;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 20.0f, 320.0f, 20.0f)];
        [_tableView setDataSource:self];
        [_tableView setDelegate:self];
        [_tableView setScrollsToTop:YES];
        
        int max = arc4random()%12345;
        max += 3214;
        for (int i = 0; i < max; i++) {
            [self.dataArray addObject:[self randomText:(arc4random()%50)+100]];
        }
    }
    
    return _tableView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger numberOfSections = 0;
    
    if ([tableView isEqual:self.tableView]) {
        numberOfSections = self.dataArray.count/20;
    }
    
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    
    if ([tableView isEqual:self.tableView]) {
        numberOfRows = self.dataArray.count %20;
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TableCellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:TableCellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
        
        
        static dispatch_once_t onceToken;
        
        dispatch_once(&onceToken, ^{
            
        });
    }
    
    [cell.textLabel setText:[NSString stringWithFormat:@"%li", (long)indexPath.row + indexPath.section*20]];
    [cell.detailTextLabel setText:[self.dataArray objectAtIndex:indexPath.row + indexPath.section * 20]];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 20.0f)];
    [headerView setBackgroundColor:[UIColor randomPastelColor]];
    
    return headerView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSLog(@"%f", scrollView.contentOffset.y);
    if (![scrollView isEqual:self.tableView]) {
        [self.tableView setContentOffset:scrollView.contentOffset];
    }
}

- (NSString *)randomText:(int)length {
    NSString *lorem = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus placerat nisi libero, quis fringilla nisi aliquet ac. Etiam quam leo, adipiscing at sollicitudin a, convallis vitae sem. Nam non pretium enim. Sed in lectus quis dui pellentesque sagittis quis nec leo. Nam id fringilla nisl, ornare commodo elit. Nam ac lacus ante. Ut vel libero et nunc facilisis gravida. \nEtiam ut urna vel nisi fringilla fringilla. Pellentesque pulvinar massa et tortor convallis euismod. Mauris sit amet est non enim sollicitudin blandit at sit amet neque. Duis fringilla pulvinar tincidunt. Donec fermentum lectus at nibh ullamcorper, non congue augue sollicitudin. Praesent et purus eu diam tristique volutpat. Fusce sodales tellus vel libero dictum, in fringilla eros feugiat. Sed tincidunt lobortis lacus id scelerisque. Vivamus eget luctus elit. Praesent euismod orci mi, vel tincidunt diam malesuada eu. Suspendisse at congue nisl. Ut rutrum, nisi sed condimentum suscipit, ipsum sem viverra metus, ac pulvinar justo tortor ut urna. Nullam ut nisi et enim volutpat consequat. Vivamus fermentum turpis purus, nec fermentum nisl lacinia eu.\nPellentesque fringilla semper enim nec ullamcorper. Quisque fermentum lacus sem, ac tempus risus viverra sit amet. Nullam rutrum turpis et sem interdum, at pretium enim sodales. Donec egestas eget lectus vitae varius. Praesent vitae diam ultrices, consectetur nulla ut, rhoncus magna. Maecenas volutpat sodales nulla at volutpat. Nulla quis porttitor ligula. Nulla eu odio elementum, pulvinar magna non, tempus felis.\nDonec elementum volutpat velit eget ullamcorper. Quisque pharetra vel eros bibendum egestas. Vestibulum vel massa eget dui gravida dapibus. Duis ac lectus nec nisl eleifend ultrices sed a mi. Sed posuere, felis nec dapibus molestie, turpis neque placerat magna, ut sagittis nisl eros vitae est. Nulla sit amet quam id enim consectetur porttitor eu quis risus. Nullam metus odio, dapibus sed diam ut, tristique posuere nisi. Nam id magna pharetra, porttitor sem vitae, sollicitudin sem. Ut et egestas dolor. Morbi rutrum velit vitae aliquam blandit.\nSed euismod ultricies purus, nec tempus erat pellentesque suscipit. Duis ut diam sed est vestibulum consequat ut quis lorem. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Maecenas varius dolor quis condimentum lacinia. In dui orci, dictum eu leo lobortis, fermentum vestibulum arcu. Praesent ullamcorper mauris nulla, eu tincidunt libero molestie sed. Integer et nibh imperdiet leo aliquet dapibus in nec lectus. Morbi eget sem ligula.";
    
    if (length > lorem.length) {
        return lorem;
    }
    
    int randomInterval = (int) lorem.length - length;
    
    NSString *string = [lorem substringWithRange:NSMakeRange(arc4random()%randomInterval, length)];
    
    if (string.length < 10) {
        string = [lorem substringWithRange:NSMakeRange(123 + arc4random()%50, 5 + arc4random()%25)];
    }
    
    if ([string rangeOfString:@" "].location != NSNotFound && string.length > 7 && [string rangeOfString:@" "].location + 1 < string.length) {
        string = [string substringFromIndex:[string rangeOfString:@" "].location + 1];
        string = [NSString stringWithFormat:@"%@%@.", [[string substringToIndex:1] uppercaseString], [string substringFromIndex:1]];
    }
    
    return string;
}

@end
