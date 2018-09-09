#include <iostream>
#include <math.h>

struct data
{
    int value[2];
};

class Cents
{
private:
    int m_nCents;
    
public:
    Cents(int nCents) { m_nCents = nCents; }
    
    // Add Cents + Cents
    //friend Cents operator+(const Cents &c1, const Cents &c2);
    
    int GetCents() { return m_nCents; }
};

// note: this function is not a member function!
bool operator > (const data &c1, const data &c2)
{
    // use the Cents constructor and operator+(int, int)
    return (c1.value[0] > c2.value[0]);
}

int main()
{
    data b;
    data a;
    data c;
    int d;
    a.value[0] = 1;
    b.value[0] = 2;
    d = a > b;
    std::cout << "I have " << d << " cents." << std::endl;
    
    return 0;
}