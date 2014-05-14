class Tester
  def foo
    bar
  end

  def bar
    baz
  end

  def baz
    sleep 1
  end
end

t1 = Thread.new do
  Tester.new.foo
end
puts "t1 started"
benchmark do
puts "t1 backtrace: #{t1.backtrace}"
t1.join
puts "t1 joined"
