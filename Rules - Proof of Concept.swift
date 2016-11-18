/*  GKRules for Business - Proof of Concept (c) 2016 Jon Gilbert */

/*
The intended use case of GKStateMachine was for games whose event loop is
based on the FPS of the game. We are using UI interactions instead,
so in each of our states there will be a simple updateEvent() method.
We call that on each component's current state when a change happens
with data of the entity that's relevant to that particular component.
*/

import Foundation
import GameKit
import GameplayKit

/* Pricing constants. */
let isDelete                 = "isDelete"
let DISCOUNTLEVELITEM        = "itemLevelDiscount"
let discountLevel            = "discountLevel"
let discountAmount           = "discountAmount"
let discountPercent          = "discountPercentage"
let totalPrice               = "totalPrice"
let percentage               = "isPercentageDiscount"

/* Static default facts we may check for. */
let ticketItemIsValid        = "ticketItemIsValid"
let discountIsItemLevel      = "discountIsItemLevel"
let discountIsPercentageType = "discountIsPercentageType"
let discountPercentageIsSet  = "discountPercentageIsSet"
let discountIsAmountType     = "discountIsAmountType"
let discountAmountIsSet      = "discountAmountIsSet"

/* GKEntities act as staging areas for business logic before changes propagate to Data Model */
class waxItemEntity:GKEntity {
    
    /* Below are the "staging" properties that change on user input but do not necessarily reflect end results
    because state changes will use rules on this. */
    var amount:Double!
    
    // Note: You must use a private _iVar like this to prevent a loop in a custom getter/setter (see below)
    private var _discountPercentValue:Double!
    
    var discountPercentValue:Double! {
        get {
            return self._discountPercentValue
        }
        set {
            self._discountPercentValue = newValue
            
            /* Notify the component of a change to the discount percentage. */
            self.priceComponent?.discountPercentDidChange()
        }
    }       // Note: "newValue" above is a Swift keyword for the incoming value form the setter
    
    private var _discountAmountValue:Double!
    var discountAmountValue:Double! {
        get { return self._discountAmountValue }
        set { self._discountAmountValue = newValue
            self.priceComponent?.discountAmountDidChange() } }
    
    /* initial state values of the entity as a dict */
    
    static let xxx:String = "asdf"
    
    /* Represents the persisted document's state at initial point */
    var ticketItemNS:[String:AnyObject]! =
    [
        // identity
        
        //        "guid"                  : xxx       ,
        //        "ticketItemID"          : xxx       ,
        //        "itemID"                : xxx       ,
        //        "itemIndex"             : xxx       ,
        //        "itemVariation"         : xxx       ,
        //        "itemName"              : xxx       ,
        
        // status
        
        "mode"                  : "DELETE"  ,
        "isDelete"              : false     ,
        "isOpenItem"            : true      ,
        "isRefundedItem"        : false     ,
        
        // sync
        
        //        "serverTicketItemID"    : xxx       ,
        
        // fees
        
        //        "fixedFeeAmount"        : xxx       ,
        
        // printing
        
        //        "printerID"             : xxx       ,
        //        "printerGroupID"        : xxx       ,
        //        "isItemPrint"           : true      ,
        
        // inventory relation
        
        //        "inventoryItemID"       : xxx       ,
        //        "categoryID"            : xxx       ,
        //        "combinationID"         : xxx       ,
        //        "skuNumber"             : xxx       ,
        //        "barCode"               : xxx       ,
        
        // pricing
        
        //        "itemCost"              : xxx       ,
        //        "itemPrice"             : xxx       ,
        
        // tax
        
        //        "taxID"                 : xxx       ,
        //        "taxAmount"             : xxx       ,
        //        "taxPercent"            : xxx       ,
        //        "salesTax"              : xxx       ,
        "totalPrice"            : 10.0      ,
        
        // discount
        
        //        "discountID"            : xxx       ,
        "discountAmount"        : 0.0       ,
        "discountPercentage"    : 0.0       ,
        "isPercentageDiscount"  : false     ,
        //        "calculatedPerDiscount" : xxx       ,
        //        "overrideAmount"        : xxx       ,
        
        // ticket relation
        
        //        "ticketNumber"          : xxx       ,
        //        "itemQuantity"          : xxx       ,
        
        "discountLevel"         : "itemLevelDiscount" ]
    
    /* Component that handles rules and state changes for pricing */
    var priceComponent:waxPriceComponent?
    
    override init() {
        super.init()
        
        print("Entity setting initial values from dictionary")
        
        /* Set up staging vars with initial values.
        Note: "as?" needs the question mark below to reassure Swift that the dictionary value
        might actually indeed be a Double. Sigh. Jesus fucking Christ. I get it, but fuck me. */
        self.discountPercentValue = self.ticketItemNS[discountPercent] as? Double
        self.discountAmountValue  = self.ticketItemNS[discountAmount]  as? Double
        self.amount               = self.ticketItemNS[totalPrice]      as? Double
        
        print("Initting price component")
        
        /* Init price component and add it. */
        self.priceComponent = waxPriceComponent.init();
        addComponent(priceComponent!)
        priceComponent?.setUpStates()
        
        print("pricing component entity = ",self.priceComponent?.entity)
        
    }
}

class waxState:GKState {
    
    var controller:AnyObject!
    var entity:waxItemEntity!
    
    init(myController:AnyObject?,myEntity:waxItemEntity!) {
        super.init()
        self.controller == nil ? self.controller = myController : ()
        self.entity     == nil ? self.entity     = myEntity     : ()
    }
    
    func attemptedStateChangeObserved() {}
    
}

class itemInittedState:waxState {
    
    override func didEnterWithPreviousState(previousState: GKState?) {
        print("entered itemInitted state")
    }
    override func willExitWithNextState(nextState: GKState) {
        print("entering discount mode")
    }
    
}


class itemReadyForPercentageDiscountApplication:waxState {
    
    override func didEnterWithPreviousState(previousState: GKState?) {
        print("entered itemReadyForPercentageDiscountApplication")
        entity.amount = entity.amount! * entity.discountPercentValue!
        
        // Don't need this next line right now, not sure what use it could be here.
        //self.willExitWithNextState(stateMachine?.stateForClass(itemInittedState))
    }
    override func willExitWithNextState(nextState: GKState?) {
        //
    }
    override func isValidNextState(stateClass: AnyClass) -> Bool {
        //
        return true
    }
    override func updateWithDeltaTime(seconds: NSTimeInterval) {
        //
    }
}

class itemReadyForAmountDiscountApplication:waxState {
    
    override func didEnterWithPreviousState(previousState: GKState?) {
        print("\n\n","entered itemReadyForAmountDiscountApplication")
        entity.amount = entity.amount! - entity.discountAmountValue!
        print(entity.amount)
    }
    override func willExitWithNextState(nextState: GKState) {
        //
    }
    override func isValidNextState(stateClass: AnyClass) -> Bool {
        //
        return true
    }
    override func updateWithDeltaTime(seconds: NSTimeInterval) {
        //
    }
}

class waxItemPricingStateMachine:GKStateMachine {
    
    override init(states: [GKState]) {
        
        super.init(states:states)
        
    }
    
}

class router:NSObject {
    //TODO:
    //move routing logic to here
    //add a better way to resolve overlaps between fact sets
    //and return a valid route
    
    //maybe use multiple rule systems one for each "junction" at the decision tree
}

class WAX_RuleFactory:NSObject {
    
    typealias exp = NSExpression
    typealias prd = NSPredicate
    typealias cmp = NSComparisonPredicate
    typealias mod = NSComparisonPredicateModifier
    typealias typ = NSPredicateOperatorType
    typealias opt = NSComparisonPredicateOptions
    
    class func newGreaterThanRule(check:String!,exceeds:AnyObject!,fact:String!,salience:Int=0,grade:Float = 1.0) -> GKRule {
        let exp1L:exp = exp(       forVariable: check    )
        let exp1R:exp = exp(  forConstantValue: exceeds  )
        let pred1:prd = cmp(
            leftExpression: exp1L, rightExpression: exp1R,
            modifier:   mod.DirectPredicateModifier,
            type:       typ.GreaterThanPredicateOperatorType,
            options:    opt.CaseInsensitivePredicateOption)
        let rule1:GKRule = GKRule.init(predicate: pred1, assertingFact:fact, grade:grade)
        rule1.salience = salience
        return rule1;
    }
    
    class func newEqualityRule(check:String!,equals:AnyObject!,fact:String!,salience:Int=0,grade:Float = 1.0) -> GKRule {
        let exp1L:exp = exp(       forVariable: check   )
        let exp1R:exp = exp(  forConstantValue: equals  )
        let pred1:prd = cmp(
            leftExpression: exp1L, rightExpression: exp1R,
            modifier:   mod.DirectPredicateModifier,
            type:       typ.EqualToPredicateOperatorType,
            options:    opt.CaseInsensitivePredicateOption)
        let rule1:GKRule = GKRule.init(predicate: pred1, assertingFact:fact, grade:grade)
        rule1.salience = salience
        return rule1;
    }
    
    class func newEqualityBan(check:String!,equals:AnyObject!,fiction:String!,salience:Int=0,grade:Float = 1.0) -> GKRule {
        let exp1L:exp = exp(       forVariable: check   )
        let exp1R:exp = exp(  forConstantValue: equals  )
        let pred1:prd = cmp(
            leftExpression: exp1L, rightExpression: exp1R,
            modifier:   mod.DirectPredicateModifier,
            type:       typ.EqualToPredicateOperatorType,
            options:    opt.CaseInsensitivePredicateOption)
        let rule1:GKRule = GKRule.init(predicate: pred1, retractingFact: fiction, grade: grade)
        rule1.salience = salience
        return rule1;
    }
}

class WAX_RuleProvider:NSObject {
    
    typealias ƒ = WAX_RuleFactory
    
    class func getPricingRules() -> [GKRule] {
        
        let rules =
        /* Equality rules */
        [   ƒ.newEqualityRule(discountLevel,      equals:DISCOUNTLEVELITEM,   fact: discountIsItemLevel       ,salience:1 ),
            ƒ.newEqualityRule(isDelete,           equals:false,               fact: ticketItemIsValid         ,salience:4 ),
            ƒ.newEqualityRule(percentage,         equals:true,                fact: discountIsPercentageType  ,salience:3 ),
            ƒ.newEqualityRule(percentage,         equals:false,               fact: discountIsAmountType      ,salience:3 ),
            
            /* Greater than rules */
            ƒ.newGreaterThanRule(discountPercent, exceeds:0.001,              fact: discountPercentageIsSet   ,salience:2 ),
            ƒ.newGreaterThanRule(discountAmount , exceeds:0.001,              fact: discountAmountIsSet       ,salience:2 )]
        
        return rules
    }
}

/* Business logic container for item pricing */
class waxPriceComponent:GKComponent {
    
    var stateMachine :GKStateMachine
    
    /* Rules processing */
    var  ruleSys      :GKRuleSystem
    
    func stateFor(vars:[String:AnyObject]) -> [AnyObject] {
        ruleSys.removeAllRules()
        ruleSys.state.removeAllObjects()
        ruleSys.state.addEntriesFromDictionary(vars)
        ruleSys.reset() //clear previous facts
        ruleSys.addRulesFromArray(WAX_RuleProvider.getPricingRules())
        ruleSys.reset() //ensure salience is respected (fails due to Apple's bug)
        
        for rule:GKRule in ruleSys.agenda {
            print("Predicate: ",rule.valueForKey("predicate")," Salience: ",rule.salience)
        }
        ruleSys.evaluate()
        return ruleSys.facts
    }
    
    /* Lookup table for conditions (GKRuleSys "facts" output) */
    var routes:[NSArray:AnyClass] =
    
    /* Route to percentage discount calculation state. */
    [[      discountIsItemLevel                                 ,
            discountPercentageIsSet                             ,
            discountIsPercentageType                            ,
            ticketItemIsValid                                   ]:
            itemReadyForPercentageDiscountApplication.self      ,
        
    /* Route to amount discount calculation state. */
    [       discountAmountIsSet                                 ,  // had to move this up one slot to make it work
            discountIsItemLevel                                 ,  // (due to Apple's bug)
            discountIsAmountType                                ,
            ticketItemIsValid                                   ]:
            itemReadyForAmountDiscountApplication.self          ]
    
    override init() {
        
        print("Creating pricing rules, rules system, and state machine")
        
        /* Init rule evaluator */
        self.ruleSys = GKRuleSystem.init()
        
        self.stateMachine = GKStateMachine.init(states: [])
        
        super.init()
    }
    
    func setUpStates() {
        print("initting states")
        
        /* Init the states array. */
        let states =
        [
            /* Initial state. */
            itemInittedState.init                                            (
                myController:self, myEntity:entity as! waxItemEntity        ) ,
            
            /* Percent discount state. */
            itemReadyForPercentageDiscountApplication.init                   (
                myController:self, myEntity:entity as! waxItemEntity        ) ,
            
            /* Amount discount state. */
            itemReadyForAmountDiscountApplication.init                       (
                myController:self, myEntity:entity as! waxItemEntity        )
            
        ];
        
        /* Init the stateMachine with the relevant states. */
        self.stateMachine = GKStateMachine.init(states: states)
        
        /* Enter the initial state. */
        self.stateMachine.enterState(itemInittedState)
    }
    
    func discountPercentDidChange() {
        
        print("Running discountDidChange")
        
        /* Cast down our heavenly entity to the depths of retail hell. */
        let item:waxItemEntity = self.entity as! waxItemEntity
        
        var stateToTransitionTo:[String:AnyObject] = item.ticketItemNS
        stateToTransitionTo[discountPercent] = item.discountPercentValue
        stateToTransitionTo[discountAmount]  = 0.0
        stateToTransitionTo[percentage]      = true; //this action could also be made a rule somehow
        transitionToState(stateToTransitionTo)
    }
    
    func transitionToState(stateToTransitionTo:[String:AnyObject]) {
        
        /* Cast down our heavenly entity to the depths of retail hell. */
        let item:waxItemEntity = self.entity as! waxItemEntity
        
        switch routes[stateFor(stateToTransitionTo)] {
        case nil:
            print("\n\n","Warning! No state found for fact set: ",ruleSys.facts);
            return
        default:
            print("Transitioning to state: ",routes[ruleSys.facts]!)
            self.stateMachine.enterState(routes[ruleSys.facts]!)
            print("price = ",item.amount)
        }
    }
    
    func discountAmountDidChange() {
        
        print("Running discountAmountDidChange")
        
        /* Cast down our heavenly entity to the depths of retail hell. */
        let item:waxItemEntity = self.entity as! waxItemEntity
        
        var stateToTransitionTo:[String:AnyObject] = item.ticketItemNS
        stateToTransitionTo[discountAmount]  = item.discountAmountValue
        stateToTransitionTo[discountPercent] = 0.0
        stateToTransitionTo[percentage]      = false //this action could also be made a rule somehow
        transitionToState(stateToTransitionTo)
    }
}

class Controller : NSObject {
    
    var item:waxItemEntity
    
    override init() {
        print("Initting entity")
        self.item = waxItemEntity.init()
        print(self.item)
    }
    
    func addDiscountPercentToItem(discount:Double!) {
        print("before:")
        print("item price: ", item.amount)
        print("discount percentage: ",item.discountPercentValue)
        print("discount to make it: ",discount)
        
        item.discountPercentValue = discount
        
        print("\n","after:")
        print("item price: ", item.amount)
        print("discount percentage: ",item.discountPercentValue)
    }
    
    func addDiscountAmountToItem(discount:Double!) {
        print("before:")
        print("item price: ", item.amount)
        print("discount amount: ",item.discountAmountValue)
        print("discount to make it: ",discount)
        
        item.discountAmountValue = discount
        
        print("\n","after:")
        print("item price: ", item.amount)
        print("discount amount: ",item.discountAmountValue)
    }
}

print("\n","Registering controller","\n")

var registerController:Controller = Controller.init()

print("\n","Proceeding with test","\n")

/* Simulated input from UI */
registerController.addDiscountPercentToItem(0.50)
registerController.addDiscountAmountToItem(2.00)

func convertStringToDictionary(text: String) -> [String:AnyObject]? {
    if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as! [String:AnyObject]
            return json
        } catch {
            
        }
    }
    return nil
}

let webRuleString:String = "{ \"domain\"    : \"TicketItem\"        , "
                         + "  \"type\"      : \"equality\"          , "
                         + "  \"salience\"  : \"4\"                 , "
                         + "  \"assertion\" : \"mode\"              , "
                         + "  \"equals\"    : \"isDelete\"          , "
                         + "  \"fact\"      : \"ticketItemIsVoid\"  } "

let webRuleDict:[String:AnyObject]! = convertStringToDictionary(webRuleString)

switch webRuleDict!["type"] as! String {
    
case "equality":
    let assertion :String!    = webRuleDict["assertion"] as! String
    let equals    :AnyObject! = webRuleDict["equals"]!
    let fact      :String!    = webRuleDict["fact"] as! String
    
    let webRule:GKRule = WAX_RuleFactory.newEqualityRule(assertion,equals:equals,fact:fact)
    break
default:
    break
}

