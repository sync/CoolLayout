//
//  Copyright (c) 2014 REAGroup. All rights reserved.
//

#import "AMMasterViewController.h"
#import "AMCollectionViewLayout.h"
#import "AMTimeAgoHeaderView.h"
#import "NSDate+TimeAgo.h"
#import "AMTopMainHeaderView.h"

static NSString * const cellIdentifier = @"CellIdentifier";

@implementation AMMasterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    AMCollectionViewLayout *layout = (AMCollectionViewLayout *)self.collectionViewLayout;
    layout.stickyHeader = YES;
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:cellIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:@"AMTimeAgoHeaderView" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[AMTimeAgoHeaderView defaultReuseIdentifier]];
    [self.collectionView registerNib:[UINib nibWithNibName:@"AMTopMainHeaderView" bundle:nil] forSupplementaryViewOfKind:AMCollectionViewLayoutElementKindHeader withReuseIdentifier:[AMTopMainHeaderView defaultReuseIdentifier]];
    
    //[self seedData];
}

- (void)seedData
{
    for (NSInteger i =0; i<100; i++)
    {
        [self insertNewObject];
    }
}

- (void)insertNewObject
{
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    
    // If appropriate, configure the new managed object.
    // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
    [newManagedObject setValue:[NSDate date] forKey:@"timeStamp"];
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:(NSString *)cellIdentifier forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:AMCollectionViewLayoutElementKindHeader])
    {
        AMTopMainHeaderView *headerView =  [collectionView dequeueReusableSupplementaryViewOfKind:AMCollectionViewLayoutElementKindHeader withReuseIdentifier:[AMTopMainHeaderView defaultReuseIdentifier] forIndexPath:indexPath];
        headerView.backgroundColor = [UIColor purpleColor];
        return headerView;
    }
    else if ([kind isEqualToString:UICollectionElementKindSectionHeader])
    {
        id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][indexPath.section];
        
        AMTimeAgoHeaderView *headerView =  [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[AMTimeAgoHeaderView defaultReuseIdentifier] forIndexPath:indexPath];
        headerView.backgroundColor = [UIColor yellowColor];
        [headerView configureWithName:sectionInfo.name];
        return headerView;
    }
    
    return nil;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    if (section == 0)
    {
        return UIEdgeInsetsMake(150.f, 0.f, 0.f, 0.f);
    }
    
    return UIEdgeInsetsZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(CGRectGetWidth(collectionView.frame), 60.f);
}

#pragma mark - AMCollectionViewLayoutDelegate 

- (CGSize)collectionView:(UICollectionView *)collectionView referenceSizeForHeaderInlayout:(UICollectionViewLayout*)collectionViewLayout
{
    return CGSizeMake(CGRectGetWidth(collectionView.frame), 40.f);
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil)
    {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"timeStamp.timeAgo" cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error])
    {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.collectionView reloadData];
}

- (void)configureCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor redColor];
    //    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    //    cell.textLabel.text = [[object valueForKey:@"timeStamp"] description];
}

@end
