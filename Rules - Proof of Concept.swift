/*  GKRules for Business - Proof of Concept (c) 2016 Jon Gilbert */

/* Paste into Swift Sandbox */

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
class G_ItemEntity:GKEntity {
    
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
    var ticketItem:[String:Any]! =
        [
            "mode"                  : "DELETE"  ,
            "isDelete"              : false     ,
            "isOpenItem"            : true      ,
            "isRefundedItem"        : false     ,
            "totalPrice"            : 10.0      ,
            "discountAmount"        : 0.0       ,
            "discountPercentage"    : 0.0       ,
            "isPercentageDiscount"  : false     ,
            "discountLevel"         : "itemLevelDiscount" ]
    
    /* Component that handles rules and state changes for pricing */
    var priceComponent:G_PriceComponent?
    
    override init() {
        super.init()
        
        print("Entity setting initial values from dictionary")
        
        /* Set up staging vars with initial values.
         Note: "as?" needs the question mark below to reassure Swift that the dictionary value
         might actually indeed be a Double. Sigh. Jesus fucking Christ. I get it, but fuck me. */
        self.discountPercentValue = self.ticketItem[discountPercent] as? Double
        self.discountAmountValue  = self.ticketItem[discountAmount]  as? Double
        self.amount               = self.ticketItem[totalPrice]      as? Double
        
        print("Initting price component")
        
        /* Init price component and add it. */
        self.priceComponent = G_PriceComponent.init();
        addComponent(priceComponent!)
        priceComponent?.setUpStates()
        
        print("pricing component entity = ",self.priceComponent?.entity)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class G_State:GKState {
    
    var controller:AnyObject!
    var entity:G_ItemEntity!
    
    init(myController:AnyObject?,myEntity:G_ItemEntity!) {
        super.init()
        self.controller == nil ? self.controller = myController : ()
        self.entity     == nil ? self.entity     = myEntity     : ()
    }
    
    func attemptedStateChangeObserved() {}
    
}

class itemInittedState:G_State {
    
    override func didEnter(from previousState: GKState?) {
        print("entered itemInitted state")
    }
    override func willExit(to nextState: GKState) {
        print("entering discount mode")
    }
    
}


class itemReadyForPercentageDiscountApplication:G_State {
    
    override func didEnter(from previousState: GKState?) {
        print("entered itemReadyForPercentageDiscountApplication")
        entity.amount = entity.amount! * entity.discountPercentValue!
        
        // Don't need this next line right now, not sure what use it could be here.
        //self.willExitWithNextState(stateMachine?.stateForClass(itemInittedState))
    }
    override func willExit(to nextState: GKState?) {
        //
    }
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        //
        return true
    }
    override func update(deltaTime seconds: TimeInterval) {
        //
    }
}

class itemReadyForAmountDiscountApplication:G_State {
    
    override func didEnter(from previousState: GKState?) {
        print("\n\n","entered itemReadyForAmountDiscountApplication")
        entity.amount = entity.amount! - entity.discountAmountValue!
        print(entity.amount)
    }
    override func willExit(to nextState: GKState) {
        //
    }
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        //
        return true
    }
    override func update(deltaTime seconds: TimeInterval) {
        //
    }
}

class G_ItemPricingStateMachine:GKStateMachine {
    
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

class G_RuleFactory:NSObject {
    
    typealias exp = NSExpression
    typealias prd = NSPredicate
    typealias cmp = NSComparisonPredicate
    typealias mod = NSComparisonPredicate.Modifier
    typealias typ = NSComparisonPredicate.Operator
    typealias opt = NSComparisonPredicate.Options
    
    class func newGreaterThanRule(check:String!,exceeds:Any!,fact:String!,salience:Int=0,grade:Float = 1.0) -> GKRule {
        let exp1L:exp = exp(       forVariable: check    )
        let exp1R:exp = exp(  forConstantValue: exceeds  )
        let pred1:prd = cmp(
            leftExpression: exp1L, rightExpression: exp1R,
            modifier:   mod.direct,
            type:       typ.greaterThan,
            options:    opt.caseInsensitive)
        let rule1:GKRule = GKRule.init(predicate: pred1, assertingFact:fact as NSObjectProtocol, grade:grade)
        rule1.salience = salience
        return rule1;
    }
    
    class func newEqualityRule(check:String!,equals:Any!,fact:String!,salience:Int=0,grade:Float = 1.0) -> GKRule {
        let exp1L:exp = exp(       forVariable: check   )
        let exp1R:exp = exp(  forConstantValue: equals  )
        let pred1:prd = cmp(
            leftExpression: exp1L, rightExpression: exp1R,
            modifier:   mod.direct,
            type:       typ.equalTo,
            options:    opt.caseInsensitive)
        let rule1:GKRule = GKRule.init(predicate: pred1, assertingFact:fact as NSObjectProtocol, grade:grade)
        rule1.salience = salience
        return rule1;
    }
    
    class func newEqualityBan(check:String!,equals:Any!,fiction:String!,salience:Int=0,grade:Float = 1.0) -> GKRule {
        let exp1L:exp = exp(       forVariable: check   )
        let exp1R:exp = exp(  forConstantValue: equals  )
        let pred1:prd = cmp(
            leftExpression: exp1L, rightExpression: exp1R,
            modifier:   mod.direct,
            type:       typ.equalTo,
            options:    opt.caseInsensitive)
        let rule1:GKRule = GKRule.init(predicate: pred1, retractingFact: fiction as NSObjectProtocol, grade: grade)
        rule1.salience = salience
        return rule1;
    }
}

class G_RuleProvider:NSObject {
    
    typealias ƒ = G_RuleFactory
    
    class func getPricingRules() -> [GKRule] {
        
        let rules =
            /* Equality rules */
            [   ƒ.newEqualityRule(check: discountLevel,      equals:DISCOUNTLEVELITEM,   fact: discountIsItemLevel       ,salience:1 ),
                ƒ.newEqualityRule(check: isDelete,           equals:false,               fact: ticketItemIsValid         ,salience:4 ),
                ƒ.newEqualityRule(check: percentage,         equals:true,                fact: discountIsPercentageType  ,salience:3 ),
                ƒ.newEqualityRule(check: percentage,         equals:false,               fact: discountIsAmountType      ,salience:3 ),
                
                /* Greater than rules */
                ƒ.newGreaterThanRule(check: discountPercent, exceeds:0.001,              fact: discountPercentageIsSet   ,salience:2 ),
                ƒ.newGreaterThanRule(check: discountAmount , exceeds:0.001,              fact: discountAmountIsSet       ,salience:2 )]
        
        return rules
    }
}

/* Business logic container for item pricing */
class G_PriceComponent:GKComponent {
    
    var stateMachine :GKStateMachine
    
    /* Rules processing */
    var  ruleSys      :GKRuleSystem
    
    func stateFor(vars:[String:Any]) -> [Any] {
        ruleSys.removeAllRules()
        ruleSys.state.removeAllObjects()
        ruleSys.state.addEntries(from: vars)
        ruleSys.reset() //clear previous facts
        ruleSys.add(G_RuleProvider.getPricingRules())
        ruleSys.reset() //ensure salience is respected (fails due to Apple's bug)
        
        for rule:GKRule in ruleSys.agenda {
            print("Predicate: ",rule.value(forKey: "predicate")," Salience: ",rule.salience)
        }
        ruleSys.evaluate()
        let facts = ruleSys.facts as! [String]
        print("facts: \(facts)")
        let facts2 = facts.sorted{ (a, b) -> Bool in
            if let aa = a as? String {
                if let bb = b as? String {
                    print("\(aa) \(bb)")
                    /*let r:Int = Int(aa.compare(bb).rawValue) 
                     print("r: \(r)")
                     return r == -1*/
                    return aa.compare(bb) == ComparisonResult.orderedAscending
                }
            }
            print("here")
            return false
        }
        print("facts: \(facts2)")
        return facts2
    }
    
    /* Lookup table for conditions (GKRuleSys "facts" output) */
    var routes:[NSArray:AnyClass] =
        
        /* Route to percentage discount calculation state. */
        [[      discountIsItemLevel                                 ,
                discountIsPercentageType                            ,
                discountPercentageIsSet                             ,
                ticketItemIsValid                                   ]:
            itemReadyForPercentageDiscountApplication.self      ,
         
         /* Route to amount discount calculation state. */
            [   discountAmountIsSet                                 ,
                discountIsAmountType                                ,
                discountIsItemLevel                                 , 
                ticketItemIsValid                                   ]:
                itemReadyForAmountDiscountApplication.self          ]
    
    override init() {
        
        print("Creating pricing rules, rules system, and state machine")
        
        /* Init rule evaluator */
        self.ruleSys = GKRuleSystem.init()
        
        self.stateMachine = GKStateMachine.init(states: [])
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpStates() {
        print("initting states")
        
        /* Init the states array. */
        let states =
            [
                /* Initial state. */
                itemInittedState.init                                           (
                    myController:self, myEntity:entity as! G_ItemEntity        ),
                
                /* Percent discount state. */
                itemReadyForPercentageDiscountApplication.init                  (
                    myController:self, myEntity:entity as! G_ItemEntity        ),
                
                /* Amount discount state. */
                itemReadyForAmountDiscountApplication.init                      (
                    myController:self, myEntity:entity as! G_ItemEntity        )
                
        ];
        
        /* Init the stateMachine with the relevant states. */
        self.stateMachine = GKStateMachine.init(states: states)
        
        /* Enter the initial state. */
        self.stateMachine.enter(itemInittedState)
    }
    
    func discountPercentDidChange() {
        
        print("Running discountDidChange")
        
        /* Cast down our heavenly entity to the depths of retail hell. */
        let item:G_ItemEntity = self.entity as! G_ItemEntity
        
        var stateToTransitionTo = item.ticketItem as [String : Any]
        stateToTransitionTo[discountPercent] = item.discountPercentValue
        stateToTransitionTo[discountAmount]  = 0.0
        stateToTransitionTo[percentage]      = true; //this action could also be made a rule 
        transitionToState(stateToTransitionTo: stateToTransitionTo)
    }
    
    func transitionToState(stateToTransitionTo:[String:Any]) {
        
        /* Cast down our heavenly entity to the depths of retail hell. */
        let item:G_ItemEntity = self.entity as! G_ItemEntity
        let key = stateFor(vars: stateToTransitionTo) as! NSArray
        let route = routes[key]
        print("\(route)")
        switch route {
        case nil:
            print("\n\n","Warning! No state found for fact set: ",route);
            return
        default:
            print("Transitioning to state: ",route)
            self.stateMachine.enter(route!)
            print("price = ",item.amount)
        }
    }
    
    func discountAmountDidChange() {
        
        print("Running discountAmountDidChange")
        
        /* Cast down our heavenly entity to the depths of retail hell. */
        let item:G_ItemEntity = self.entity as! G_ItemEntity
        
        var stateToTransitionTo = item.ticketItem as [String:Any] 
        stateToTransitionTo[discountAmount]  = item.discountAmountValue
        stateToTransitionTo[discountPercent] = 0.0
        stateToTransitionTo[percentage]      = false //this action could also be made a rule somehow
        transitionToState(stateToTransitionTo: stateToTransitionTo)
    }
}

class G_Controller : NSObject {
    
    var item:G_ItemEntity
    
    override init() {
        print("Initting entity")
        self.item = G_ItemEntity.init()
        print(self.item)
    }
    
    func addDiscountPercentToItem(discount:Double!) {
        print("adding discount...")
        print("item price before adding percentage discount: ", item.amount)
        print("discount: ",discount)
        
        item.discountPercentValue = discount
        
        print("item price after adding percentage discount: ", item.amount)
    }
    
    func addDiscountAmountToItem(discount:Double!) {
        print("adding discount...")
        print("item price before adding amount discount: ", item.amount)
        print("discount: ",discount)
        
        item.discountAmountValue = discount
        
        print("item price after adding amount discount: ", item.amount)
    }
}


/******** RUN SECTION ***********/

print("\n","Registering controller","\n")

var register = G_Controller.init()

print("\n","Proceeding with test","\n")

/* Simulated input from UI */
register.addDiscountPercentToItem(discount: 0.50)
register.addDiscountAmountToItem(discount: 2.00)

/********************************/

func convertStringToDictionary(text: String) -> [String:AnyObject]? {
    if let data = text.data(using: String.Encoding.utf8) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as! [String:AnyObject]
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

let webRuleDict:[String:AnyObject]! = convertStringToDictionary(text: webRuleString)

switch webRuleDict!["type"] as! String {
    
case "equality":
    let assertion :String!    = webRuleDict["assertion"] as! String
    let equals    :AnyObject! = webRuleDict["equals"]!
    let fact      :String!    = webRuleDict["fact"] as! String
    
    let webRule:GKRule = G_RuleFactory.newEqualityRule(check: assertion,equals:equals,fact:fact)
    break
default:
    break
}
