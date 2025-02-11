import { Injectable } from '@nestjs/common';
import { CreateUserDto } from './dto/create-user.dto';
import { PrismaService } from 'nestjs-prisma';

import { User } from '@prisma/client';
import { UpdateUsernameDto } from './dto/update-username.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async create(data: CreateUserDto): Promise<User> {
    const { address, email, username } = data;

    const newUser = await this.prisma.user.create({
      data: {
        address,
        email,
        username,
      },
    });

    return newUser;
  }

  async findAll() {
    return this.prisma.user.findMany();
  }

  async findOne(id: string) {
    return this.prisma.user.findUnique({
      where: {
        id,
      },
    });
  }

  async findOneByAddress(address: string) {
    return this.prisma.user.findUnique({
      where: {
        address,
      },
    });
  }

  remove(id: number) {
    return `This action removes a #${id} user`;
  }

  async updateUsername(
    userId: string,
    updateUsernameDto: UpdateUsernameDto,
  ): Promise<User> {
    const { username } = updateUsernameDto;

    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: { username },
    });

    return updatedUser;
  }

  async findOneByUsername(username: string) {
    return this.prisma.user.findUnique({
      where: {
        username,
      },
    });
  }
}
