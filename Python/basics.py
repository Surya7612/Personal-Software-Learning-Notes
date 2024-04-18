class Employee:
    num_of_emp = 0
    raise_amount = 1.04
    '''Double underscore is called dunder'''
    def __init__(self, first, last, pay):
        ''' Here, every instance we create of Employee using self such as first, last, pay and email is instance variable, data that is unique to each instance. '''
        self.first = first 
        self.last = last
        self.pay = pay
        self.email = first + '.' + last + '@company.com'
        Employee.num_of_emp += 1 #increment the number of employees every time we instantiate a new employee, here there is no use of using self, we need the constant 
    
    def fullname(self):
        return '{} {}'.format(self.first, self.last)
    
    def apply_raise(self):
        self.pay = int(self.pay * self.raise_amount) # can also be accessed by Employee.raise_amount 
        '''advantage of using self here is the ability to change the raise_amount for a single instance if you want to and also that any subclass can override the 
        raise_amount.'''

    def pay_after_raise(self):
        self.apply_raise()
        return self.pay
    
    '''Regular messages automatically passes instance (self) as the first argument and Class methods passes class as the first argument, we call it as 'cls'.'''
    '''Class Variables are variables that are shared among all instances of a class, they should be the same for each instance.'''    
    @classmethod
    def set_raise_amt(cls, amount):
        cls.raise_amount = amount
    
    @classmethod
    def from_string(cls, emp_str): #Alternative Constructor
        first,last, pay = emp_str.split('-')
        return cls(first,last,pay)
    
    '''Static methods don't pass anything automatically as their first argument,instance or the class. They behave just like regular functions except we 
    include them in our classes because they have some logical connections with the class.'''
    @staticmethod
    def is_workday(day):
        '''In Python, dates have weekday methods where Monday = 0 and Sunday is 6, and the days in between'''
        if day.weekday() == 5 or day.weekday() == 6:
            return False
        return True
    ''' To know when to use Static method is the scenario where you don't us eor access any instance or the class within the function.'''

    '''Special Methods: Dunder init, dunder repr, dunder str,etc; repr and str help us to change how our objects are printed and displayed.'''

    ''' repr is meant to be an unambiguous representaion of the object and should be used for debugging, logging, etc  '''
    def __repr__(self): 
        return f"Employee('{self.first}', '{self.last}', {self.pay})"

    '''str is meant to be more of a readable representation of the object and is meant to be displayed as a display to the end user'''
    def __str__(self):
        return f'{self.fullname()} - {self.email}'
    
    #Another example of dunder special method
    def __add__(self, other):
        return self.pay + other.pay
    
'''Inheriting from Employee class, Developer is subclass and Employee is Super class or Parent class'''
'''When we input a function to a subclass, python follows the 'method resolution order', which is the chain of classes that it goes through to find what the method is.
All classes have the built-in group of methods and attributes as their primary order. '''
class Developer(Employee):
    raise_amount = 1.10

    def __init__(self, first, last, pay, prog_lang):
        super().__init__(first, last, pay) #can also use Employee.__init__(first,last,pay), but super is more conventional when there's singular inheritance
        self.prog_lang = prog_lang

class Manager(Employee):
    def __init__(self, first, last, pay, employees=None): #Never pass mutable data types like a list or dictionary as default arguments
        super().__init__(first, last, pay)
        if employees is None:
            self.employees = []
        else:
            self.employees = employees
    
    def add_employee(self, emp):
        if emp not in self.employees:
            self.employees.append(emp)
    
    def remove_employee(self, emp):
        if emp in self.employees:
            self.employees.remove(emp)
    
    def print_emps(self):
        for emp in self.employees:
            print('-->', emp.fullname())
    

emp_1 = Employee('Surya', 'Nediyadeth', 70000)
emp_2 = Employee('Test','User', 50000)

dev_1 = Developer('Dev', 'Test', 100000, 'Python') # Python and Java are entered after adding the additional argument in Developer class
dev_2 = Developer('Devi', 'Test2', 120000, 'Java')

mgr_1 = Manager('Test', 'Manager', 80000, [dev_1])

# Testing for Employee class
print(emp_1.email)
print(emp_2.email)

print('The full name is {} {} '.format(emp_1.first,emp_1.last)) # '.format' usage
print(f"The full name is {emp_2.first} {emp_2.last}") # 'f-string' usage
print('The full name is', emp_1.fullname()) # using method above
print('The full name is', Employee.fullname(emp_1)) #using classname

print("The pay for {} before the raise is {}, and after the raise is {}".format(emp_1.first, emp_1.pay, emp_1.pay_after_raise()))

emp_2.raise_amount = 1.05
print(f'The pay for {emp_2.first} before the raise is {emp_2.pay}, and after the raise is {emp_2.pay_after_raise()} ')

#After using class method
Employee.set_raise_amt(1.05)
print(Employee.raise_amount)

#class methods as Alternative Constructors, it means we can use these class methods in order to provide multiple ways of creating our object
#Example: creating employee using strings
emp_str_1 = 'John-Doe-80000'
emp_str_2 = 'Steve-Smith-90000'
emp_str_3 = 'Jane-Doe-40000'

'''Updated above in class'''
# #split the string
# first,last,pay = emp_str_1.split('-') 
# new_emp_1 = Employee(first, last, pay)

new_emp_1 = Employee.from_string(emp_str_1)

print(new_emp_1.pay)
print(new_emp_1.email)

#checking static method
import datetime
my_date = datetime.date(2016, 7, 10)
print(Employee.is_workday(my_date))
my_date_1 = datetime.date(2016, 7, 11)
print(Employee.is_workday(my_date_1))

#Testing for developer class, before any changes or input

print('Developer-1 Email: ',dev_1.email) #checking Developer class inheritance without adding anything in the class. Working Fine.

print('Developer-1 Programming Language: ',dev_1.prog_lang)

# print("The pay for {} before the raise is {}, and after the raise is {}".format(dev_1.first, dev_1.pay, dev_1.pay_after_raise())) #runs fine

#Testing after changing raise_amount in Developer class.
print("The pay for {} before the raise is {}, and after the raise is {}".format(dev_1.first, dev_1.pay, dev_1.pay_after_raise())) #runs fine

''' 'help' function helps in visulaizing the method resolution order. '''
# print(help(Developer)) 

#Testing for Manager class
print('Manager_1 Email: ',mgr_1.email)
print('Employees:')
mgr_1.print_emps()

mgr_1.add_employee(dev_2)
print('After adding employee:')
mgr_1.print_emps()

mgr_1.remove_employee(dev_1)

print('After removing employee:')
mgr_1.print_emps()

#isinstance and issubclass
print(isinstance(mgr_1, Employee)) #lets you know if an object is an instance of a class
print(isinstance(mgr_1, Developer))

print(issubclass(Manager, Employee)) #lets you know if a class is a subclass of another class
print(issubclass(Manager, Developer))


#Testing special methods
print(emp_1.__repr__())
print(emp_1.__str__())
print(emp_1 + emp_2)