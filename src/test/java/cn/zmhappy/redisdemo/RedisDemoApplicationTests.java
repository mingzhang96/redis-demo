package cn.zmhappy.redisdemo;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;
import redis.clients.jedis.JedisCluster;

@RunWith(SpringRunner.class)
@SpringBootTest
public class RedisDemoApplicationTests {

	@Autowired
	JedisCluster jedisCluster;

	@Test
	public void contextLoads() {
	}

	@Test
	public void jedisTest() {
		jedisCluster.set("faceall2", "bb");

	}

}
