package cn.zmhappy.redisdemo;

import cn.zmhappy.redisdemo.jedis.JedisClusterConfig;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;
import redis.clients.jedis.JedisCluster;
import redis.clients.jedis.JedisPubSub;

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

//	private String channel_name = "Selected_Camera_Channel";
    private String channel_name = "zhangming";
//    private String channel_name = "selectedCameraIds";

    @Test
	public void serverTest() {
		try {
			for (int i = 0; i < 1000000; i++) {
				jedisCluster.publish(channel_name, i+"");
				Thread.sleep(200);
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	@Test
	public void clientTest() {
	    while (true) {
	        try {
                jedisCluster.subscribe(new JedisPubSub() {
                    @Override
                    public void onMessage(String channel, String message) {
                        System.out.println("getting message from " + channel + " : " + message);
                    }

                    @Override
                    public void onSubscribe(String channel, int subscribedChannels) {
                        System.out.println("subscribe successfully!");
                    }
                }, channel_name);
            } catch (Exception e) {
//                jedisCluster = new JedisClusterConfig().jedisCluster();
                e.printStackTrace();
            }

        }
	}

}
